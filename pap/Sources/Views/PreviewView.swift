//
//  PreviewView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos

protocol PreviewViewDelegate {
    func batchPreviewView(_ view: PreviewView, didSelectItemAt indexPath: IndexPath)
    func batchPreviewViewWillFinalize(_ view: PreviewView)

    func batchPreviewView(_ view: PreviewView, didUpdateProgress progress: Float)
    func batchPreviewView(_ view: PreviewView, didUpdateRemoteFetchingProgress progress: Float)
    func batchPreviewView(_ view: PreviewView, didUpdateInternalProgress progress: Float)

    func batchPreviewViewWillCancelProgress(_ view: PreviewView)

    func batchPreviewViewWillBeginEdit(_ view: PreviewView)
    func batchPreviewViewDidEndEdit(_ view: PreviewView)
    func batchPreviewViewDidCancelEdit(_ view: PreviewView)
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

class PreviewView: CustomView, AppDockContentTransition {
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
    
    private var transitionBeginLocation: CGPoint = .zero
    func transitionWillBegin(at location: CGPoint) {
        transitionBeginLocation = location
    }
    
    public func updatePreviews(animated: Bool = true, forced: Bool = false, completion: (() -> Void)? = nil) {
        setPreviewLayout(with: collectionViewHeightLayout.constant)
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { continue }
            let appAsset = appAssetsSelected.at(indexPath.item)
            if appAsset.editState.hasChanges || forced {
                if let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) {
                    renderPreviewProcessing(with: cell, at: indexPath)
                }
                else {
                    cell.assetView.filteredImage = nil //INFO: clear when app changed
                    cell.setImageEditItem(appAsset.editState, animated: animated)
                }
            }
        }
    }
    
    public func setPreviewLayout(with height: CGFloat) {
        let toLayout = PreviewCollectionLayout(previewHeight: height)
        
        let touchedIndexPath = collectionView.indexPathForItem(at: transitionBeginLocation)
        
        collectionViewHeightLayout.constant = height
//        collectionView.layoutIfNeeded() // for test
        //FIXME: A strange main queue BAD_EXEC crash: https://www.evernote.com/l/AEGXgIlYWZhOyp29B4mJH804vQ1tZaVWS7wB/image.png
        collectionView.setCollectionViewLayout(toLayout, animated: false)
        
        if appAssetsSelected.count > 0, let indexPath = touchedIndexPath {
            scrollToNeareastItem(at: indexPath, animated: false)
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
            collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: [insertedIndexPath])
            }) { fin in
                guard fin else { return }
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.scrollToNeareastItem(at: insertedIndexPath)
            }
        }
        
        return insertedIndexPath
    }

    @discardableResult
    func removeCollectionViewItem(with asset: PHAsset?) -> IndexPath? {
        guard let _asset = asset, let indexPath = appAssetsSelected.remove(for:_asset) else {
            return nil
        }
        
        if appAssetsSelected.count > 0 {
            collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [indexPath])
            }) { fin in
                guard fin else { return }
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.scrollToNeareastItem(at: indexPath)
            }
        }
        else {
            collectionView.reloadData()
        }
        
        return indexPath
    }
    
    func removeCollectionViewItems(with assets: [PHAsset]?) {
        guard let _assets = assets, !_assets.isEmpty else {
            return
        }
        
        let indexPaths = _assets.compactMap({ appAssetsSelected.by($0)?.indexPath })
        _assets.forEach { appAssetsSelected.remove(for: $0) }
        
        if appAssetsSelected.count > 0 {
            collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: indexPaths)
            }) { fin in
                guard fin else { return }
                self.collectionView.collectionViewLayout.invalidateLayout()
                if let indexPath = indexPaths.first {
                    self.scrollToNeareastItem(at: indexPath)
                }
            }
        }
        else {
            collectionView.reloadData()
        }
    }
    
    func scrollToNeareastItem(at indexPath: IndexPath, animated: Bool = true) {
        if appAssetsSelected.count > 0 {
            let nearestItem = indexPath.item < appAssetsSelected.count ? indexPath.item : max(min(indexPath.item - 1, appAssetsSelected.count - 2), 0)
            collectionView.scrollToItem(at: IndexPath(item: nearestItem, section: 0), at: .centeredHorizontally, animated: animated)
        }
    }

    func removeAllCollectionViewItems() {
        appAssetsSelected.removeAll()
        collectionView.reloadData()
    }

    func reloadCollectionViewItems(animated: Bool = true) {
        updatePreviews(animated: animated)
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

        scrollToNeareastItem(at: IndexPath(item: 0, section: targetSection))

        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchProgressChanged), name: RemoteSourceFetchNotification.Name.progressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.processingProgressChanged), name: PHAssetProgressNotification.Name.progressChanged, object: nil)

        //TODO: BatchAppCenter.default.task.append immediatly from UI action instead of using "EditItems"

        for i in 0..<appAssetsSelected.count{
            AppCenter.default.task.append(request: AppTaskRequest(app, appAssetsSelected.at(i)))
        }
        AppCenter.default.task.perform(createTaskReaction())
        papLog.performFromUser()

        papCount.app.countToPerform()

        return true
    }

    public func createTaskReaction() -> AppTaskReaction{
        let reaction = AppTaskReaction()

        reaction.when(progress:{ response, progress, remained, completed in
            assert(response.info.state != .completed || response.info.state == .completed && response.result != nil, "task state is .completed but result is nil")

            let requestedParam = response.request.param as? AppAsset
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
            self.scrollToNeareastItem(at: IndexPath(item: destItem, section: index.section))


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
        if let progress = sender.userInfo?[PHAssetProgressNotification.UserInfo.Key.progress] as? Float {
            DispatchQueue.main.async {
                self.delegate?.batchPreviewView(self, didUpdateInternalProgress: progress)
            }
        }
    }
    
    func cancelBatchProcessing() {
        assert(AppCenter.default.task.isRunning)

        NotificationCenter.default.removeObserver(self, name: RemoteSourceFetchNotification.Name.progressChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: PHAssetProgressNotification.Name.progressChanged, object: nil)


        self.delegate?.batchPreviewViewWillCancelProgress(self)
        UIApplication.shared.beginIgnoringInteractionEvents()

        AppCenter.default.task.cancel(AppTaskCancellationReaction().will {
            UIApplication.shared.endIgnoringInteractionEvents()
        }.did{
//            self.delegate?.batchPreviewViewDidEndEdit(self)
            self.delegate?.batchPreviewViewDidCancelEdit(self)
        })
    }
}

public struct PreviewProcessingQueue {
    fileprivate static var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = PreviewProcessingQueue.dispatchQueue
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .utility
        return operationQueue
    }()
    fileprivate static let dispatchQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
    
    //INFO: controlQueue must be higher than dispatchQueue for its priority
    fileprivate static let controlQueue =  DispatchQueue.main
    
    //INFO: Access all following properties only with dispatchQueue when write
    fileprivate static let indexPathQueue = ItemQueue<IndexPath>()
    
    //INFO: Write 'canceled' must be a dispatchqueue that has earlier QoS than .utility
    fileprivate static var canceled = false
    
    private static var cachedPreviewImages = [String: URL]()
    
    private static func cacheIdentifier(with item: AppAsset, targetSize: CGSize) -> String? {
        guard let lastEditState = item.editState.imageEditStateValue else { return  nil }
        return "\(item.asset.localIdentifierWithoutSplitter)_\(targetSize)_\(lastEditState.hash))"
    }
    
    fileprivate static func cacheImage(_ image: UIImage, targetSize: CGSize, with item: AppAsset) {
        guard let identifier = cacheIdentifier(with: item, targetSize: targetSize) else { return }
        let url = FileURL.temp(identifier, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
        if cachedPreviewImages[identifier] == nil, let data = UIImageJPEGRepresentation(image, 0.7), (try? data.write(to: url)) != nil {
            cachedPreviewImages[identifier] = url
        }
    }
    
    fileprivate static func cachedImage(item: AppAsset, targetSize: CGSize) -> UIImage? {
        guard let identifier = cacheIdentifier(with: item, targetSize: targetSize) else { return nil }
        guard let url = cachedPreviewImages[identifier] else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

extension PreviewView {
    fileprivate func enqueuePreviewProcessing(at indexPath: IndexPath) {
        PreviewProcessingQueue.dispatchQueue.async{
            if false == PreviewProcessingQueue.indexPathQueue.enqueued(where:{ $0 == indexPath }){
                PreviewProcessingQueue.indexPathQueue.enqueue(indexPath)
            }
            
            DispatchQueue.main.async {
                self.performPreviewProcessing()
            }
        }
    }
    
    fileprivate func performPreviewProcessing() {
        guard let app = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) else {
            cancelPreviewProcessing()
            return
        }
        
        let targetSize = CGSize(width: min(self.bounds.width, self.bounds.height), height: min(self.bounds.width, self.bounds.height))
        
        func performNext() {
            PreviewProcessingQueue.operationQueue.addOperation { [unowned self] in
                guard let indexPath = PreviewProcessingQueue.indexPathQueue.dequeue() else { return }
                
                DispatchQueue.main.async{
                    guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { return }
                    cell.assetView.isProcessing = true
                }
                
                if let item = AppAssets.selected.at(unsafeIndex:indexPath.item) {
                    DispatchQueue.main.async{
                        guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { return }
                        cell.setOriginalImage(with: item)
                    }
                    
                    app.previewProcessing(item, targetSize: targetSize, completion: { (original, filtered) in
                        if let image = filtered {
                            PreviewProcessingQueue.cacheImage(image, targetSize: targetSize, with: item)
                        }
                        
                        DispatchQueue.main.async{
                            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { return }
                            cell.setFilteredImage(filtered, original: original, with: item)
                            cell.assetView.isProcessing(false, animated: true)
                        }
                        performNext()
                    })
                }
                
                if PreviewProcessingQueue.canceled {
                    PreviewProcessingQueue.indexPathQueue.dequeueAll()
                    PreviewProcessingQueue.operationQueue.cancelAllOperations()
                    return
                }
            }
        }
        
        PreviewProcessingQueue.controlQueue.async {
            PreviewProcessingQueue.canceled = false
            autoreleasepool {
                performNext()
            }
        }
    }
    
    fileprivate func cancelPreviewProcessing(){
        PreviewProcessingQueue.controlQueue.async{
            if PreviewProcessingQueue.indexPathQueue.count == 0 {
                return
            }
            PreviewProcessingQueue.canceled = true
        }
    }
}

extension PreviewView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appAssetsSelected.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.previewCollectionViewCell.name, for: indexPath) as! PreviewCollectionViewCell
        cell.delegate = self
        
        if let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) {
            cell.assetView.isProcessing = true
        }
        else {
            let item = appAssetsSelected.at(indexPath.item)
            cell.setEditItemForPreview(item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        renderPreviewProcessing(with: cell as! PreviewCollectionViewCell, at: indexPath)
    }
    
    private func renderPreviewProcessing(with cell: PreviewCollectionViewCell, at indexPath: IndexPath) {
        guard let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) else { return }
        
        let item = appAssetsSelected.at(indexPath.item)
        
        let targetSize = CGSize(width: min(self.bounds.width, self.bounds.height), height: min(self.bounds.width, self.bounds.height))
        if let cached = PreviewProcessingQueue.cachedImage(item: item, targetSize: targetSize) {
            cell.assetView.isProcessing = false
            cell.setFilteredImage(cached, with: item)
        }
        else {
            cell.setOriginalImage(with: item)
            cell.assetView.isProcessing = true
            
            enqueuePreviewProcessing(at: indexPath)
        }
    }
}

extension PreviewView: PreviewCollectionViewCellDelegate {
    func previewCollectionViewCellDidChangeLayoutAttributes(_ cell: PreviewCollectionViewCell, at indexPath: IndexPath) {
        if let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) {
            renderPreviewProcessing(with: cell, at: indexPath)
        }
        else {
            let item = appAssetsSelected.at(indexPath.item)
            cell.setEditItemForPreview(item)
        }
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
