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

    func batchPreviewView(_ view: PreviewView, didUpdateProgress progress: Progress)
    func batchPreviewView(_ view: PreviewView, didUpdateRemoteFetchingProgress progress: Progress)
    func batchPreviewView(_ view: PreviewView, didUpdateInternalProgress progress: Progress)
    func batchPreviewView(_ view: PreviewView, didUpdateFinalizingProgress progress: Progress)

    func batchPreviewViewWillCancelProgress(_ view: PreviewView)

    func batchPreviewViewWillBeginEdit(_ view: PreviewView)
    func batchPreviewViewDidEndEdit(_ view: PreviewView, assetsForFinished assets: [PHAsset])
    func batchPreviewViewDidCancelEdit(_ view: PreviewView)
    
    func batchPreviewView(_ view: PreviewView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool
    func batchPreviewView(_ view: PreviewView, titleForMenuItemAt indexPath: IndexPath) -> String?
    func batchPreviewView(_ view: PreviewView, didSelectMenuItemAt indexPath: IndexPath)
}

internal class PreviewCollectionLayout: UICollectionViewLayout {
    var previewHeight: CGFloat = 0
    
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
    
    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
    
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
    
    private func estimatedSizeForItem(at indexPath: IndexPath, in collectionView: UICollectionView) -> CGSize {
        guard let appAsset = AppAssets.selected.at(unsafeIndex: indexPath.item) else { return .zero }
        
        let asset = appAsset.asset
        
        let contentInset = collectionView.contentInset
        let maximumHeight = min(previewHeight, collectionView.bounds.width)
        
        let contentSize = CGRect(origin: .zero, size: CGSize(width: maximumHeight, height: maximumHeight)).inset(by: contentInset).size
        let boundingSize = CGSize(width: contentSize.height, height: contentSize.height)
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        let cellSize = photoSize.applying(appAsset.editState.transform).magnitude
        
        return CGSize(width: cellSize.width, height: floor(contentSize.height))
    }
    
    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let collectionView = self.collectionView else { return .zero }
        return estimatedSizeForItem(at: indexPath, in: collectionView)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[.item]?[indexPath]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache[.item]?.compactMap({ rect.intersects($0.value.frame) ? $0.value : nil })
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return collectionView?.bounds.height != newBounds.height
    }
    
    var contentSize: CGSize {
        return CGSize(width: _contentSize.width - paddingLeft - paddingRight, height: _contentSize.height)
    }
    
    func estimatedContentSize(collectionView: UICollectionView) -> CGSize {
        var itemPositionX: CGFloat = 0
        var contentSize: CGSize = .zero
        
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        
        for indexPath in (0 ..< numberOfItems).map({ IndexPath(item: $0, section: 0) }) {
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let itemSize = estimatedSizeForItem(at: indexPath, in: collectionView)
            
            let itemPosition = CGPoint(x: itemPositionX, y: (previewHeight - itemSize.height) / 2)
            attributes.frame = CGRect(origin: itemPosition, size: itemSize)
            itemPositionX += itemSize.width + minimumSpacing
            
            contentSize.width = attributes.frame.maxX
            contentSize.height = attributes.frame.height
        }
        
        let paddingLeft = contentSize.width > collectionView.bounds.width ? minimumSpacing * 2 : (collectionView.bounds.width - contentSize.width) / 2
        let paddingRight = paddingLeft
        
        contentSize.width += paddingLeft + paddingRight
        
        return CGSize(width: contentSize.width - paddingLeft - paddingRight, height: contentSize.height)
    }
    
    override var collectionViewContentSize: CGSize {
        return _contentSize
    }
}

enum BatchProcessingState {
    case ready
    case processing
    case finalizing
}

class PreviewView: CustomView, AppDockContentTransition {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightLayout: NSLayoutConstraint!
    
    var delegate: PreviewViewDelegate?

    let appAssetsSelected = AppAssets.selected
    let _preferences = AppDockContentPreferences(preferredHeight:44)
    
    private var batchProcessingState = BatchProcessingState.ready

    override func initialize() {
        super.initialize()

        print("[i] BatchAppCenter.default.task.maxConcurrentCount: ", AppCenter.default.task.maxConcurrentCount)

        collectionViewHeightLayout.constant = _preferences.preferredHeight
        collectionView.collectionViewLayout = PreviewCollectionLayout(previewHeight: collectionViewHeightLayout.constant)
        
        collectionView.contentInset.top = 1
        collectionView.contentInset.bottom = 1
        collectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: PreviewCollectionViewCell.self))
    }
    
    private var transitionBeginLocation: CGPoint?
    func transitionWillBegin(at location: CGPoint) {
        transitionBeginLocation = location
    }
    
    public func updatePreviews(animated: Bool = true, forced: Bool = false, completion: (() -> Void)? = nil) {
        setPreviewLayout(with: collectionViewHeightLayout.constant)
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard
                let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell,
                let appAsset = appAssetsSelected.at(unsafeIndex: indexPath.item)
            else { continue }
            
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
    
    private func setPreviewLayout(with height: CGFloat) {
        if UIMenuController.shared.isMenuVisible {
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
        
        let fromLayout = collectionView.collectionViewLayout as? PreviewCollectionLayout
        let toLayout = PreviewCollectionLayout(previewHeight: height)
        
        guard fromLayout?.contentSize != toLayout.estimatedContentSize(collectionView: self.collectionView) else { return }
        
        var targetIndexPath: IndexPath? = nil
        let location = transitionBeginLocation ?? CGPoint(x: collectionView.bounds.width / 2, y: 0)
        var targetLocation = collectionView.convert(location, from: self)
        targetLocation.y = collectionView.bounds.height / 2
        
        targetIndexPath = collectionView.indexPathForItem(at: targetLocation) ?? IndexPath(item: location.x > collectionView.contentSize.width / 2 ? appAssetsSelected.count - 1 : 0, section: 0)
        
        transitionBeginLocation = nil
        
        collectionViewHeightLayout.constant = height
        
        UIView.performWithoutAnimation { [unowned self] in
            self.collectionView.performBatchUpdates(nil) { [unowned self] _ in
                self.collectionView.setCollectionViewLayout(toLayout, animated: false)
                if self.appAssetsSelected.count > 0, let indexPath = targetIndexPath {
                    self.scrollToNeareastItem(at: indexPath, animated: false)
                }
            }
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
    
    func removeCollectionViewItems(with assets: [PHAsset]?) {
        guard let _assets = assets, !_assets.isEmpty else {
            return
        }
        
        let indexPaths = _assets.compactMap({ appAssetsSelected.index(for: $0) }).map { IndexPath(item: $0, section: 0)}
        _assets.forEach { AppAssets.selected.remove(for: $0) }
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.finalizingProgressChanged), name: PHAssetFinalizableNotification.Name.progressChanged, object: nil)

        //TODO: BatchAppCenter.default.task.append immediatly from UI action instead of using "EditItems"

        for i in 0..<appAssetsSelected.count{
            AppCenter.default.task.append(request: AppTaskRequest(app, appAssetsSelected.at(i)))
        }
        AppCenter.default.task.perform(createTaskReaction())
        papLog.performFromUser()

        papDefaults.app.countToPerform()

        return true
    }
    
    public var isTaskRunning: Bool {
        return batchProcessingState != .ready
    }

    public func createTaskReaction() -> AppTaskReaction{
        let reaction = AppTaskReaction()
        
        batchProcessingState = .processing

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
            let destItem = Int(Float(totalCount-1)*Float(progress.fractionCompleted)).clamped(to: 0...numberOfItems-1)

            //TODO: confirm - https://fabric.io/jessi/ios/apps/com.stells.batch/issues/5aca0f2936c7b23527e26e8a?time=last-thirty-days
            self.scrollToNeareastItem(at: IndexPath(item: destItem, section: index.section))


        }).will(finish: { resultsByApps, respondables in

            self.batchProcessingState = .finalizing
            self.delegate?.batchPreviewViewWillFinalize(self)


        }).did(finish: { resultsByApps, respondables in
            assert(!AppCenter.default.task.isRunning)
            
            guard self.batchProcessingState != .ready else { return }
            
            let assets = respondables.compactMap { respondable -> PHAsset? in
                if respondable.info.userInfo[AppTaskInfo.UserInfo.Key.removedOnCompletion] as? Bool == true {
                    return (respondable.request.param as? AppAsset)?.asset
                }
                else {
                    return nil
                }
            }

            self.batchProcessingState = .ready
            self.delegate?.batchPreviewViewDidEndEdit(self, assetsForFinished: assets)

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
        if let progress = sender.userInfo?[RemoteSourceFetchNotification.UserInfo.Key.progress] as? Progress {
            DispatchQueue.main.async {
                self.delegate?.batchPreviewView(self, didUpdateRemoteFetchingProgress: progress)
            }
        }
    }
    
    @objc func processingProgressChanged(sender: NSNotification) {
        if let progress = sender.userInfo?[PHAssetProgressNotification.UserInfo.Key.progress] as? Progress {
            DispatchQueue.main.async {
                self.delegate?.batchPreviewView(self, didUpdateInternalProgress: progress)
            }
        }
    }
    
    @objc func finalizingProgressChanged(sender: NSNotification) {
        if let progress = sender.userInfo?[PHAssetFinalizableNotification.UserInfo.Key.progress] as? Progress {
            DispatchQueue.main.async {
                self.delegate?.batchPreviewView(self, didUpdateFinalizingProgress: progress)
            }
        }
    }
    
    func cancelBatchProcessing() {
        if AppCenter.default.task.isRunning {
            cancelProcessing()
        }
        else if batchProcessingState == .finalizing {
            cancelFinalizing()
        }
    }
    
    private func cancelProcessing() {
        assert(AppCenter.default.task.isRunning)
        
        NotificationCenter.default.removeObserver(self, name: RemoteSourceFetchNotification.Name.progressChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: PHAssetProgressNotification.Name.progressChanged, object: nil)
        
        self.batchProcessingState = .ready
        self.delegate?.batchPreviewViewWillCancelProgress(self)
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        AppCenter.default.task.cancel(AppTaskCancellationReaction().will {
            UIApplication.shared.endIgnoringInteractionEvents()
            }.did{
                self.delegate?.batchPreviewViewDidCancelEdit(self)
        })
        
        papLog.cancelWhilePerforming()
    }
    
    private func cancelFinalizing() {
        guard let app = AppCenter.default.currentInstanceAs(PHAssetFinalizableApp.self) else { return }
        app.cancelFinalizing()
        
        self.batchProcessingState = .ready
        self.delegate?.batchPreviewViewDidCancelEdit(self)
    }
}

fileprivate struct PreviewProcessingQueue {
    fileprivate static var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = PreviewProcessingQueue.dispatchQueue
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .utility
        return operationQueue
    }()
    fileprivate static let dispatchQueue = DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility)
    
    //INFO: controlQueue must be higher than dispatchQueue for its priority
    fileprivate static let controlQueue =  DispatchQueue.main
    
    //INFO: Access all following properties only with dispatchQueue when write
    fileprivate static let indexPathQueue = ItemQueue<IndexPath>()
    
    //INFO: Write 'canceled' must be a dispatchqueue that has earlier QoS than .utility
    fileprivate static var canceled = false
    
    private static var cachedPreviewImages: NSCache = NSCache<NSString, NSURL>()
    
    private static func cacheIdentifier(with item: AppAsset, targetSize: CGSize) -> String? {
        guard let lastEditState = item.editState.imageEditStateValue else { return  nil }
        return "\(item.asset.localIdentifierWithoutSplitter)_\(targetSize)_\(lastEditState.hash))"
    }
    
    fileprivate static func cacheImage(_ image: UIImage, targetSize: CGSize, with item: AppAsset) {
        guard let identifier = cacheIdentifier(with: item, targetSize: targetSize) else { return }
        let url = FileURL.temp(identifier as String, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
        
        if cachedPreviewImages.object(forKey: identifier as NSString) == nil, let data = image.jpegData(compressionQuality: 0.7), (try? data.write(to: url)) != nil {
            cachedPreviewImages.setObject(url as NSURL, forKey: identifier as NSString)
        }
    }
    
    fileprivate static func cachedImage(item: AppAsset, targetSize: CGSize) -> UIImage? {
        guard let identifier = cacheIdentifier(with: item, targetSize: targetSize) else { return nil }
        guard let url = cachedPreviewImages.object(forKey: identifier as NSString), let filePath = url.path else { return nil }
        return UIImage(contentsOfFile: filePath)
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
    
    fileprivate func needsShowProcessingEffect() -> Bool {
        return AppCenter.default.currentInstanceAs(PreviewProcessableApp.self)?.showsVisibleEffectWhileProcessing() == true
    }

    //TODO: fix a case of cached but reprocessing, it appears when the process performs with heavy filters.
    //TODO: fix a case of first item is reprocessing once more.
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
                    cell.assetView.isProcessing = self.needsShowProcessingEffect()
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
                        
                        DispatchQueue.main.async {
                            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { return }
                            if let originalImage = app.previewOriginalImageCompare(with: item, targetSize: targetSize) ?? original {
                                cell.assetView.originalImageForCompare = originalImage
                                cell.assetView.originalBadgeTitle = app.previewOriginalBadgeTitle
                            }
                            cell.setFilteredImage(filtered, original: original, with: item)
                            if cell.assetView.isProcessing {
                                cell.assetView.isProcessing(false, animated: true)
                            }
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
            cell.assetView.isProcessing = needsShowProcessingEffect()
        }
        else if let item = appAssetsSelected.at(unsafeIndex: indexPath.item) {
            cell.setEditItemForPreview(item)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        renderPreviewProcessing(with: cell as! PreviewCollectionViewCell, at: indexPath)
    }
    
    private func renderPreviewProcessing(with cell: PreviewCollectionViewCell, at indexPath: IndexPath) {
        guard
            let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self),
            let item = appAssetsSelected.at(unsafeIndex: indexPath.item)
        else { return }
        
        let targetSize = CGSize(width: min(self.bounds.width, self.bounds.height), height: min(self.bounds.width, self.bounds.height))
        if let cached = PreviewProcessingQueue.cachedImage(item: item, targetSize: targetSize) {
            cell.assetView.isProcessing = false
            cell.setFilteredImage(cached, with: item)
        }
        else {
            cell.setOriginalImage(with: item)
            cell.assetView.isProcessing = needsShowProcessingEffect()
            
            enqueuePreviewProcessing(at: indexPath)
        }
    }
}

extension PreviewView: PreviewCollectionViewCellDelegate {
    func previewCollectionViewCellDidChangeLayoutAttributes(_ cell: PreviewCollectionViewCell, at indexPath: IndexPath) {
        if let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) {
            renderPreviewProcessing(with: cell, at: indexPath)
        }
        else if let item = appAssetsSelected.at(unsafeIndex: indexPath.item) {
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
        
        if delegate?.batchPreviewView(self, shouldShowMenuForItemAt: indexPath) == true, let menuTitle = delegate?.batchPreviewView(self, titleForMenuItemAt: indexPath), let cell = collectionView.cellForItem(at: indexPath) {
            becomeFirstResponder()
            
            UIMenuController.shared.setTargetRect(convert(cell.frame, from: collectionView), in: self)
            UIMenuController.shared.menuItems = [UIMenuItem(title: menuTitle, action: #selector(self.performActionForMenuItem))]
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        if let indexPath = collectionView.indexPathsForSelectedItems?.first, delegate?.batchPreviewView(self, shouldShowMenuForItemAt: indexPath) == true {
            return true
        }
        return super.canBecomeFirstResponder
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(self.performActionForMenuItem)
    }
    
    @objc func performActionForMenuItem(sender: UIMenuController) {
        guard let indexPath = collectionView.indexPathsForSelectedItems?.first else { return }
        delegate?.batchPreviewView(self, didSelectMenuItemAt: indexPath)
    }
}
