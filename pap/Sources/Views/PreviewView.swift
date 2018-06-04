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
    
    override func prepare() {
        super.prepare()
        
        prepareCache()
        
        var itemPositionX: CGFloat = 0
        _contentSize = .zero
        
        guard let numberOfItems = collectionView?.numberOfItems(inSection: 0) else { return }
        
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
        
        centerAlignment()
    }
    
    public func centerAlignment() {
        guard let numberOfItems = collectionView?.numberOfItems(inSection: 0), numberOfItems > 0 else { return }
        if let first = layoutAttributesForItem(at: IndexPath(item: 0, section: 0)), let bounds = collectionView?.bounds.size {
            collectionView?.contentInset.left = (bounds.width - first.bounds.width) / 2
        }
        
        if let last = layoutAttributesForItem(at: IndexPath(item: numberOfItems - 1, section: 0)), let bounds = collectionView?.bounds.size {
            collectionView?.contentInset.right = (bounds.width - last.bounds.width) / 2
        }
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
        return _contentSize
    }
    
    override var collectionViewContentSize: CGSize {
        return self.contentSize
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
        updateCollectionViewAlignment(animated: false)
    }

    public func updatePreviews(animated: Bool = true, completion: (() -> Void)? = nil) {
        collectionView.setCollectionViewLayout(PreviewCollectionLayout(previewHeight: collectionViewHeightLayout.constant), animated: animated)

        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { continue }

            let appAsset = appAssetsSelected.at(indexPath.item)
            if appAsset.editState.hasChanges{
                cell.setImageEditItem(appAsset.editState, animated: animated)
            }
        }

        updateCollectionViewAlignment(animated: false)
    }
    
    public func reloadPreview(with height: CGFloat) {
        let needsToRestoreContentOffset = collectionViewHeightLayout.constant != height
        let offsetXRatio = (collectionView.contentOffset.x + collectionView.contentInset.left) / collectionView.collectionViewLayout.collectionViewContentSize.width
        
        collectionViewHeightLayout.constant = height
        collectionView.layoutIfNeeded()
        
        let toLayout = PreviewCollectionLayout(previewHeight: height)
        collectionView.setCollectionViewLayout(toLayout, animated: false)
        updateCollectionViewAlignment(animated: false)
        
        if appAssetsSelected.count > 0 && needsToRestoreContentOffset {
            collectionView.contentOffset.x = offsetXRatio * toLayout.collectionViewContentSize.width - collectionView.contentInset.left
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
        reloadPreview(with:_preferences.preferredHeight)
    }

    func reloadContentThatFits(size:CGSize) {
        reloadPreview(with:size.height)
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
        }
        self.updateCollectionViewAlignment(animated: false)
        self.collectionView.scrollToItem(at: insertedIndexPath, at: .centeredHorizontally, animated: true)

        return insertedIndexPath
    }

    func removeCollectionViewItem(with asset: PHAsset?) {
        guard let _asset = asset, let indexPath = appAssetsSelected.remove(for:_asset) else {
            return
        }

        collectionView.deleteItems(at: [indexPath])
        updateCollectionViewAlignment()

        if appAssetsSelected.count > 0 {
            let nearestItem = max(min(indexPath.item - 1, appAssetsSelected.count - 2), 0)
            collectionView.scrollToItem(at: IndexPath(item: nearestItem, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    func appendCollectionViewItems(with assets: [PHAsset]) {
        let prevCount = appAssetsSelected.count
        let indexPaths = assets.compactMap { appAssetsSelected.put(with: $0) }
        
        if appAssetsSelected.count>prevCount{
            self.collectionView.insertItems(at: indexPaths)
        }
        self.updateCollectionViewAlignment(animated: false)
        
        if let indexPath = indexPaths.last {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func removeCollectionViewItems(with assets: [PHAsset]) {
        let indexPaths = assets.compactMap { appAssetsSelected.remove(for: $0) }
        
        collectionView.deleteItems(at: indexPaths)
        updateCollectionViewAlignment()
        
        if appAssetsSelected.count > 0, let indexPath = indexPaths.last {
            let nearestItem = max(min(indexPath.item - 1, appAssetsSelected.count - 2), 0)
            collectionView.scrollToItem(at: IndexPath(item: nearestItem, section: 0), at: .centeredHorizontally, animated: true)
        }
    }

    func removeAllCollectionViewItems() {
        let indexPaths = (0..<appAssetsSelected.count).map({ IndexPath(item: $0, section: 0) })

        appAssetsSelected.removeAll()
        collectionView.deleteItems(at: indexPaths)
        updateCollectionViewAlignment()
    }

    func updateCollectionViewAlignment(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                (self.collectionView.collectionViewLayout as? PreviewCollectionLayout)?.centerAlignment()
            }
        }
        else {
            (collectionView.collectionViewLayout as? PreviewCollectionLayout)?.centerAlignment()
        }
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
            for (app, results) in resultsByApps{
                for r in results{
                    if let e = r.info.error{
                        Crashlytics.sharedInstance().recordError(e, withAdditionalUserInfo: [
                            "app.identifier":app.identifier
                            ,"task.state": "\(r.info.state)"
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
