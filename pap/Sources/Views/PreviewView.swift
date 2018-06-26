//
//  PreviewView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos
import Crashlytics

struct PreviewCachingImageManager {
    private static var cachedImages = [AppAsset: URL]()
    
    static func startCachingImage(_ asset: AppAsset, image: UIImage) {
        let url = FileURL.temp("preview_cached_image_\(asset.editState.hash).jpg")
        
        DispatchQueue(label: "preview_caching_queue").async {
            let data = UIImageJPEGRepresentation(image, 0.7)
            try? data?.write(to: url)
            PreviewCachingImageManager.cachedImages[asset] = url
        }
    }
    
    static func cachedImage(_ asset: AppAsset) -> UIImage? {
        guard let url = PreviewCachingImageManager.cachedImages[asset] else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    static func stopCachingImage(_ asset: AppAsset) {
        if let cachedIndex = PreviewCachingImageManager.cachedImages.index(forKey: asset), let url = PreviewCachingImageManager.cachedImages[asset] {
            try? FileManager.default.removeItem(at: url)
            PreviewCachingImageManager.cachedImages.remove(at: cachedIndex)
        }
    }
    
    static func stopCachingImagesForAllAssets() {
        PreviewCachingImageManager.cachedImages.forEach { (appAsset, url) in
            try? FileManager.default.removeItem(at: url)
        }
        PreviewCachingImageManager.cachedImages.removeAll()
    }
}

protocol PreviewViewDelegate {
    func batchPreviewView(_ view: PreviewView, didSelectItemAt indexPath: IndexPath)
    func batchPreviewViewWillFinalize(_ view: PreviewView)

    func batchPreviewView(_ view: PreviewView, didUpdateProgress progress: Float)
    func batchPreviewView(_ view: PreviewView, didUpdateRemoteFetchingProgress progress: Float)
    func batchPreviewView(_ view: PreviewView, didUpdateInternalProgress progress: Float)

    func batchPreviewViewWillCancelProgress(_ view: PreviewView)

    func batchPreviewViewWillBeginEdit(_ view: PreviewView)
    func batchPreviewViewDidEndEdit(_ view: PreviewView)
}

internal class PreviewCollectionLayout: UICollectionViewLayout {
    var previewHeight: CGFloat = 0 {
        didSet {
            invalidateLayout()
        }
    }
    
    private enum LayoutItem: String {
        case item = "Item"
        case header = "UICollectionElementKindSectionHeader"
        case footer = "UICollectionElementKindSectionFooter"
    }
    private var cache = [LayoutItem: [IndexPath: UICollectionViewLayoutAttributes]]()
    private func prepareCache() {
        cache.removeAll()
        
        cache[.item] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.header] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.footer] = [IndexPath: UICollectionViewLayoutAttributes]()
    }
    
    init(previewHeight: CGFloat = 0) {
        super.init()
        self.previewHeight = previewHeight
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var minimumSpacing: CGFloat = 1
    private var _contentSize: CGSize = .zero
    
    public private(set) var paddingLeft: CGFloat = 0
    public private(set) var paddingRight: CGFloat = 0
    
    override func prepare() {
        super.prepare()
        
        prepareCache()
        
        var itemPositionX: CGFloat = 0
        _contentSize = .zero
        
        guard let collectionView = self.collectionView else { return }
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        
        for indexPath in (0 ..< numberOfItems).map({ IndexPath(item: $0, section: 0) }) {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let itemSize = sizeForItem(at: indexPath)
            
            let itemPosition = CGPoint(x: itemPositionX, y: (previewHeight - itemSize.height) / 2)
            attributes.frame = CGRect(origin: itemPosition, size: itemSize)
            itemPositionX += itemSize.width + minimumSpacing
            
            cache[.item]?[indexPath] = attributes
            
            _contentSize.width = attributes.frame.maxX
            _contentSize.height = attributes.frame.height
        }
        
        paddingLeft = _contentSize.width > collectionView.bounds.width ? minimumSpacing * 2 : (collectionView.bounds.width - _contentSize.width) / 2
        paddingRight = paddingLeft
        
        cache[.item]?.forEach({ (indexPath, attributes) in
            attributes.frame.origin.x += paddingLeft
        })
        
        _contentSize.width += paddingLeft + paddingRight
    }
    
    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let collectionView = self.collectionView else { return .zero }
        
        let asset = AppAssets.selected.at(indexPath.item).asset
        
        let contentInset = collectionView.contentInset
        let maximumHeight = min(previewHeight, collectionView.bounds.width)
        
        let contentSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: CGSize(width: maximumHeight, height: maximumHeight)), contentInset).size
        let boundingSize = CGSize(width: contentSize.height, height: contentSize.height)
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        let cellSize = photoSize.applying(AppAssets.selected.at(indexPath.item).editState.transform).magnitude
        
        return CGSize(width: cellSize.width, height: floor(contentSize.height))
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[.item]?[indexPath]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache[.item]?.compactMap({ rect.intersects($0.value.frame) ? $0.value : nil })
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
    
    var contentSize: CGSize {
        return CGSize(width: _contentSize.width - paddingLeft - paddingRight, height: _contentSize.height)
    }
    
    override var collectionViewContentSize: CGSize {
        return _contentSize
    }
}

class PreviewView: CustomView {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightLayout: NSLayoutConstraint!
    
    var delegate: PreviewViewDelegate?

    let appAssetsSelected = AppAssets.selected
    let _preferences = AppDockContentPreferences(preferredHeight:44)

    override func initialize() {
        super.initialize()

        print("[i] BatchAppCenter.default.task.maxConcurrentCount: ", AppCenter.default.task.maxConcurrentCount)

        collectionViewHeightLayout.constant = _preferences.preferredHeight
        collectionView.collectionViewLayout = PreviewCollectionLayout(previewHeight: collectionViewHeightLayout.constant)
        
        collectionView.contentInset.top = 1
        collectionView.contentInset.bottom = 1
        collectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: PreviewCollectionViewCell.self))
    }

    public func updatePreviews(animated: Bool = true, forced: Bool = false, completion: (() -> Void)? = nil) {
        setPreviewLayout(with: collectionViewHeightLayout.constant)

        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { continue }

            let appAsset = appAssetsSelected.at(indexPath.item)
            if appAsset.editState.hasChanges || forced {
                cell.setAssetItem(appAsset, at: indexPath, forced: true, animated: animated)
            }
        }
    }
    
    public func setPreviewLayout(with height: CGFloat) {
        guard let fromLayout = collectionView.collectionViewLayout as? PreviewCollectionLayout else { return }
        let toLayout = PreviewCollectionLayout(previewHeight: height)
        
        let offsetXRatio = collectionView.contentOffset.x / fromLayout.contentSize.width
        
        collectionViewHeightLayout.constant = height
        collectionView.layoutIfNeeded()
        collectionView.setCollectionViewLayout(toLayout, animated: false)
        
        if appAssetsSelected.count > 0 {
            collectionView.setContentOffset(CGPoint(x: offsetXRatio * toLayout.contentSize.width, y: collectionView.contentOffset.y), animated: false)
        }
    }
}

extension PreviewView: AppDockContentView, AppDockContent {
    //AppDockContentDescribable
    var view: UIView {
        return self
    }
    var preferences: AppDockContentPreferable? {
        return _preferences
    }

    func reloadContent() {
        setPreviewLayout(with:_preferences.preferredHeight)
    }

    func reloadContentThatFits(size:CGSize) {
        setPreviewLayout(with:size.height)
    }
}

extension PreviewView {
    @discardableResult
    func appendCollectionViewItem(with asset: PHAsset) -> IndexPath? {
        let prevCount = appAssetsSelected.count
        guard let insertedIndexPath = appAssetsSelected.put(with:asset) else {
            return nil
        }

        if appAssetsSelected.count>prevCount{
            self.collectionView.insertItems(at: [insertedIndexPath])
            self.collectionView.scrollToItem(at: insertedIndexPath, at: .centeredHorizontally, animated: true)
        }

        return insertedIndexPath
    }

    @discardableResult
    func removeCollectionViewItem(with asset: PHAsset?) -> IndexPath? {
        guard let _asset = asset, let indexPath = appAssetsSelected.remove(for:_asset) else {
            return nil
        }

        collectionView.deleteItems(at: [indexPath])
        
        scrollToNeareastItem(at: indexPath)
        
        return indexPath
    }
    
    func scrollToNeareastItem(at indexPath: IndexPath) {
        if appAssetsSelected.count > 0 {
            let nearestItem = indexPath.item < appAssetsSelected.count ? indexPath.item : max(min(indexPath.item - 1, appAssetsSelected.count - 1), 0)
            collectionView.scrollToItem(at: IndexPath(item: nearestItem, section: 0), at: .centeredHorizontally, animated: true)
        }
    }

    func removeAllCollectionViewItems() {
        let indexPaths = (0..<appAssetsSelected.count).map({ IndexPath(item: $0, section: 0) })

        appAssetsSelected.removeAll()
        collectionView.deleteItems(at: indexPaths)
    }

    func reloadCollectionViewItems() {
        updatePreviews()
    }
}

extension PreviewView {

    //TODO: remove dependencies and export from previewview
    @discardableResult
    func runBatchProcessing() -> Bool {
        let targetSection = 0 //TODO: previously support multiple sections

        guard let app = AppCenter.default.current, collectionView.numberOfItems(inSection: targetSection) > 0 else {
            assert(false, "selected app does not exist.")
            return false
        }

        //TODO: append dynamically more items where Set(EditItems) - Set(alreadyqueued Items) BatchAppCenter.default.task.query(by:_)
        delegate?.batchPreviewViewWillBeginEdit(self)

        collectionView.scrollToItem(at: IndexPath(item: 0, section: targetSection), at: .centeredHorizontally, animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchProgressChanged), name: RemoteSourceFetchNotification.Name.progressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.processingProgressChanged), name: PHAssetProcessableNotification.Name.progressChanged, object: nil)

        //TODO: BatchAppCenter.default.task.append immediatly from UI action instead of using "EditItems"

        for i in 0..<appAssetsSelected.count{
            AppCenter.default.task.append(request: AppTaskRequest(app, appAssetsSelected.at(i)))
        }
        AppCenter.default.task.perform(createTaskReaction())
        papLog.event.performFromUser()

        return true
    }

    public func createTaskReaction() -> AppTaskReaction{
        let reaction = AppTaskReaction()

        reaction.when(progress:{ response, progress, remained, completed in
            assert(response.info.state != .completed || response.info.state == .completed && response.result != nil, "task state is .completed but result is nil")

            let requestedParam = response.request.param as? PHAssetItem<ImageEditStateValue>
            let totalCount = remained.count+completed.count

            assert(totalCount>0, "totalCount == 0 but progress has started")
            if totalCount == 0{
                return
            }

            if response.info.state != .completed {
                // all - (cancelled + completed)
                return
            }

            //completed
            self.delegate?.batchPreviewView(self, didUpdateProgress: progress)

            guard let param = requestedParam
                , let index = param.indexPath else {
                return
            }

            let numberOfItems = self.collectionView.numberOfItems(inSection: index.section)
            if numberOfItems == 0{
                return
            }

            // it is possible totalCount != numberOfItems (e.g. if an item was runtime-removed while progress as batch tasks)
            let destItem = Int(Float(totalCount-1)*progress).clamped(to: 0...numberOfItems-1)

            //TODO: confirm - https://fabric.io/jessi/ios/apps/com.stells.pap/issues/5aca0f2936c7b23527e26e8a?time=last-thirty-days
            self.collectionView.scrollToItem(at: IndexPath(item: destItem, section: index.section), at: .centeredHorizontally, animated: true)


        }).will(finish: { resultsByApps, respondables in

            self.delegate?.batchPreviewViewWillFinalize(self)


        }).did(finish: { resultsByApps, respondables in
            assert(!AppCenter.default.task.isRunning)

            self.delegate?.batchPreviewViewDidEndEdit(self)

            //log
            for (_, results) in resultsByApps{
                for r in results{
                    if let e = r.info.error{
                        papLog.error.recordedError(e, parameters:[
                            "task.state": "\(r.info.state)"
                        ])
                    }
                }
            }
        })

        return reaction
    }
    
    @objc func fetchProgressChanged(sender: NSNotification) {
        if let progress = sender.userInfo?[RemoteSourceFetchNotification.UserInfo.Key.progress] as? Float {
            DispatchQueue.main.async {
                self.delegate?.batchPreviewView(self, didUpdateRemoteFetchingProgress: progress)
            }
        }
    }
    
    @objc func processingProgressChanged(sender: NSNotification) {
        if let progress = sender.userInfo?[PHAssetProcessableNotification.UserInfo.Key.progress] as? Float {
            DispatchQueue.main.async {
                self.delegate?.batchPreviewView(self, didUpdateInternalProgress: progress)
            }
        }
    }
    
    func cancelBatchProcessing() {
        assert(AppCenter.default.task.isRunning)

        NotificationCenter.default.removeObserver(self, name: RemoteSourceFetchNotification.Name.progressChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: PHAssetProcessableNotification.Name.progressChanged, object: nil)


        self.delegate?.batchPreviewViewWillCancelProgress(self)
        UIApplication.shared.beginIgnoringInteractionEvents()

        AppCenter.default.task.cancel(AppTaskCancellationReaction().will {
            UIApplication.shared.endIgnoringInteractionEvents()
        }.did{
            self.delegate?.batchPreviewViewDidEndEdit(self)
        })
    }
}

extension PreviewView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appAssetsSelected.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.previewCollectionViewCell.name, for: indexPath) as! PreviewCollectionViewCell
        cell.setEditItemForPreview(appAssetsSelected.at(indexPath.item), at: indexPath)
        return cell
    }
}

extension PreviewView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !AppCenter.default.task.isRunning
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.batchPreviewView(self, didSelectItemAt: indexPath)
    }
}
