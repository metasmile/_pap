//
//  PhotoPickerViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 7. 11..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import Hero

fileprivate struct PhotoEditorTransitionContext {
    var sourceView: UIView
    var placeholderView: UIImageView
}

class PhotoPickerViewController: AppDockViewController {
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    var batchPreviewView: PreviewView!
    
    private var taskProgress: Float = 0

    var dragSelectionGesture: DragSelectionGestureRecognizer!

    var collection: PHAssetCollection?
    var defaultCollection: PHAssetCollection?{
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject
    }
    var isCurrentCollectionDefault:Bool{
        return self.collection?.localIdentifier == self.defaultCollection?.localIdentifier
    }
    var queuedPhotoLibraryChanges = ItemQueue<PHChange>()
    
    fileprivate var photoEditorTransitionContext: PhotoEditorTransitionContext?
    
    private var animatesUpdatingPhotoCollectionContentInset = false
    
    private var needsScrollToBottom = false
    
    func setNeedsScrollToBottom() {
        needsScrollToBottom = true
    }

    var scrollingBottomOffsetY:CGFloat{
        return max(-photoCollectionView.adjustedContentInset.top, photoCollectionView.contentSize.height - photoCollectionView.bounds.size.height + photoCollectionView.adjustedContentInset.bottom - collectionView(photoCollectionView, layout: photoCollectionView.collectionViewLayout, referenceSizeForFooterInSection: 0).height)
    }

    var scrollBottomOffsetYIncludingMargin:CGFloat{
        return photoCollectionView.contentSize.height - photoCollectionView.bounds.size.height + photoCollectionView.adjustedContentInset.bottom
    }
    
    func scrollToBottomIfNeeded(animated:Bool=false) {
        guard needsScrollToBottom else { return }
        needsScrollToBottom = false

        photoCollectionView.setContentOffset(CGPoint(x: 0, y: scrollingBottomOffsetY), animated: animated)
    }

    override func viewDidLoad() {
        self.appDockView?.delegate = self

        super.viewDidLoad()

        //preview
        batchPreviewView = PreviewView(frame: .zero)
        batchPreviewView.delegate = self

        //photos collection
        photoCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: PhotoCollectionViewCell.self))
        photoCollectionView.register(PhotoPickerFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "PhotoPickerFooterView")
        photoCollectionView.allowsMultipleSelection = true
        
        //peek and pop
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: photoCollectionView)  // self here is UIViewController type, and view is property of UIViewController
            registerForPreviewing(with: self, sourceView: batchPreviewView)
        }

        //listen PHPhotoLibrary changes
        PhotosManager.default.watch(\.changes) {
            guard let changeInstance = PhotosManager.default.changes else { return }

            DispatchQueue.main.async{
                self.queuedPhotoLibraryChanges.enqueue(changeInstance)

                self.cancelPreheatingIfNeeded()

                if AppCenter.default.task.isRunning == false{
                    self.flushQueuedPhotoLibraryChanges()
                }
            }
        }

        //monitor latest AppCenter task
        AppCenter.default.task.watch(\.appIdentifiersFinished) {
            DispatchQueue.main.async{
                self.flushQueuedPhotoLibraryChanges()
            }

            //remove temp files after current all tasks are finished.
            //TODO: domain-driven disk management. (if app did mark for maintaining cache resources, skip)
            DispatchQueue.global(qos: .background).async{
                FileManager.default.clearTemporaryDirectory()
            }

            papLog.allTasksAreFinished()
        }
        
        navigationItem.setLeftBarButton(nil, animated: false)
        navigationItem.setRightBarButton(nil, animated: false)

        //check photo library permission and load
        loadPhotoLibraryIfNeeded()
        
        dragSelectionGesture = DragSelectionGestureRecognizer(target: self, action: #selector(self.dragSelectionGestureDidRecognize))
        dragSelectionGesture.delegate = self
        photoCollectionView.addGestureRecognizer(dragSelectionGesture)

        //AppCenter.chargeManager related
        initializeChargeWhenViewDidLoad()

        //INFO: maintain last
        updateUIDisplays()
    }
    
    @objc private func loadPhotoLibraryIfNeeded() {
        PhotosManager.default.authorizeIfNeeded { authorized in
            DispatchQueue.main.async{ // if not call from DispatchQueue.main.async, scroll will not work.
                if authorized {
                    self.loadPhotoLibraryInCurrentCollection()
                }
                else {
                    self.navigationItem.hidesBackButton = true
                    self.navigationItem.setLeftBarButton(UIBarButtonItem(title: "⚠️", style: .plain, target: self, action: #selector(self.loadPhotoLibraryIfNeeded)), animated: true)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appDockNavigationController?.setAppDockHidden(false, animated: animated)

        AppCenter.default.openCurrentApp()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animatesUpdatingPhotoCollectionContentInset = true
        
        if let app = AppCenter.default.currentInstanceAs(EditableApp.self) {
            app.selectEditStateValue(app.defaultEditStateValue, in: (app as? AppDockApp)?.content)
        }

        updateUIDisplays()
        registerChargeObservingTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterChargeObservingTimer()
        cancelPreheatingIfNeeded()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        photoCollectionView.collectionViewLayout.invalidateLayout()
    }

    private func loadPhotoLibraryInCurrentCollection(){
        if self.collection == nil {
            self.collection = self.defaultCollection
            self.titleFade = self.collection?.localizedTitle ?? Bundle.main.displayName
        }

        //QA: attach initial progress activity view + non-mainqueue.async
        if let collection = self.collection {
            PHAssets.fetched.load(from: collection)
        }
        else {
            PHAssets.fetched.load(with: .smartAlbum, subtype: .smartAlbumUserLibrary) // iphone x: .028702974319458s
        }

        if let numberOfSection = PHAssets.fetched.results?.count, numberOfSection > 0
        , let numberOfItemsInSection = PHAssets.fetched.results?[numberOfSection - 1].count
        , numberOfItemsInSection > 0 {
            self.setNeedsScrollToBottom()
        }
        self.photoCollectionView.reloadData()
        self.photoCollectionView.performBatchUpdates(nil, completion: { result in
            self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
            self.scrollToBottomIfNeeded(animated: true)
        })

        //navigation controller accessories
        self.title = self.collection?.localizedTitle ?? Bundle.main.displayName
    }

    private func flushQueuedPhotoLibraryChanges(){
        assert(Thread.isMainThread, "flushQueuedPhotoLibraryChanges must be called in main")

        var countOfOtherFetched = 0
        while let changeInstance = self.queuedPhotoLibraryChanges.dequeue() {
            //changed, but if found actual changes from other collection has existed (e.g. current == Favorite, but captured on Camera app)
            if self.photoLibraryDidChangeInCurrentFetched(changeInstance) == nil{
                countOfOtherFetched += 1
            }
        }

        //FIXME: after pop -> entered any album again -> some other PHChange is arriving (probably seems Album's PHChange_. strange.
//        if !self.isCurrentCollectionDefault && countOfOtherFetched > 0{
//            self.navigationController?.popViewController(animated: true)
//        }
    }
    
    override var appDockItems: [AppDockItem] {
        return AppCenter.default.apps(by: .default).map { AppDockItem(app: $0) }
    }
    
    override func appDidChange() {
        super.appDidChange()
        
        AppAssets.selected.reloadAll()
        
        if let app = AppCenter.default.currentInstanceAs(EditableApp.self) {
            let value = app.defaultEditStateValue
            if let value = value {
                AppAssets.selected.appendValue(value)
            }
            
            app.selectEditStateValue(value, in: (app as? AppDockApp)?.content)
        }
        
        redisplayVisibleCellsEnabled()
        appDockView?.reloadKeepingDrawerOpened()
        batchPreviewView.updatePreviews(forced: true)

        updateUIDisplays()
        showAndRevertTitleByCurrentAppIfNeeded() //INFO: show app name after update title

        cancelPreheatingIfNeeded()
        performPrefetchIfNeeded(includingCurrentVisibleItems: true)

        //TODO: for iPad - popoverPresentation sourceView is not works - see u at next update
    }
    
    override func registerWatchingAppConfig() {
        AppCenter.default.watch(\.currentIdentifier, options: [.new, .old, .initial]) { (appCenter, dict) in

            AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id: "picker\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform, !AppCenter.default.task.isRunning {
                    self.setAppValue(value)
                }
            }

            AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.watch(\.filter, id: "picker\(FiltersApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.task.isRunning {
                    self.setAppValue(value)
                }
            }

            AppCenter.default.currentInstanceAs(AutoEditorApp.self)?.config?.watch(\.filter, id: "picker\(AutoEditorApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.task.isRunning {
                    self.setAppValue(value)
                }
            }

            AppCenter.default.currentInstanceAs(Stabilizer.self)?.config?.watch(\.stabilizationMode, id: "picker\(Stabilizer.info.identifier)") { (config, changed) in
                if let value = config.stabilizationMode, !AppCenter.default.task.isRunning {
                    self.setAppValue(value)
                }
            }

            AppCenter.default.currentInstanceAs(GIFMakerApp.self)?.config?.watch(\.sourceType, id: "picker\(GIFMakerApp.info.identifier)") { (config, changed) in
                self.redisplayVisibleCells()
            }

            AppCenter.default.currentInstanceAs(ConverterApp.self)?.config?.watch(\.convertingDirectionIdentifier, id: "picker\(ConverterApp.info.identifier)") { (config, changed) in
                self.redisplayVisibleCells()
            }

            //TODO: make a group for preheatable apps
            AppCenter.default.currentInstanceAs(RevertApp.self)?.watch(\.autoSelect, id: "picker\(RevertApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }

            AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.watch(\.autoSelect, id: "picker\(PhoneCallsApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }

            AppCenter.default.currentInstanceAs(ExifGhostApp.self)?.watch(\.autoSelect, id: "picker\(ExifGhostApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }

            AppCenter.default.currentInstanceAs(FinderApp.self)?.watch(\.autoSelect, id: "picker\(FinderApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }
            
            AppCenter.default.currentInstanceAs(CleanerApp.self)?.watch(\.autoSelect, id: "picker\(CleanerApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }
        }
    }
    
    private func setAppValue(_ value: ImageEditStateValue) {
        AppAssets.selected.appendValue(value)
        
        if let app = AppCenter.default.currentInstanceAs(EditableApp.self) {
            app.setDefaultEditStateValue(value)
        }
        
        batchPreviewView.updatePreviews()
    }
    
    override func unregisterWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["picker\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.unwatch(\.filter, forIds:["picker\(FiltersApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(AutoEditorApp.self)?.config?.unwatch(\.filter, forIds:["picker\(AutoEditorApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(Stabilizer.self)?.config?.unwatch(\.stabilizationMode, forIds:["picker\(Stabilizer.info.identifier)"])
        AppCenter.default.currentInstanceAs(GIFMakerApp.self)?.config?.unwatch(\.sourceType, forIds:["picker\(GIFMakerApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ConverterApp.self)?.config?.unwatch(\.convertingDirectionIdentifier, forIds:["picker\(ConverterApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(RevertApp.self)?.unwatch(\.autoSelect, forIds:["picker\(RevertApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(PhoneCallsApp.self)?.unwatch(\.autoSelect, forIds:["picker\(PhoneCallsApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ExifGhostApp.self)?.unwatch(\.autoSelect, forIds:["picker\(ExifGhostApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(FinderApp.self)?.unwatch(\.autoSelect, forIds:["picker\(FinderApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(CleanerApp.self)?.unwatch(\.autoSelect, forIds:["picker\(CleanerApp.info.identifier)"])

        AppCenter.default.unwatchAllFilePrivate(\.currentIdentifier)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if animatesUpdatingPhotoCollectionContentInset {
            UIView.animateAsSpring(animations: {
                self.photoCollectionView.contentInset.bottom = self.appDockInsets.bottom
                self.photoCollectionView.scrollIndicatorInsets.bottom = self.photoCollectionView.contentInset.bottom
            })
        }
        else {
            self.photoCollectionView.contentInset.bottom = self.appDockInsets.bottom
            self.photoCollectionView.scrollIndicatorInsets.bottom = self.photoCollectionView.contentInset.bottom
        }
    }

    override func cancelButtonDidTap(sender: Any) {
        super.cancelButtonDidTap(sender: sender)

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        cancelAllInCurrentContext()
    }
    
    private var finalizingViewController: AppUIActionFinalizationViewController?
    
    override func doneButtonDidTap(sender: Any) {
        super.doneButtonDidTap(sender: sender)
        
        batchPreviewView.runBatchProcessing()
        
        updateVisibleCellsEnabled()

        cancelPreheatingIfNeeded()
        
        guard let app = AppCenter.default.current else { return }
        
        guard let vc = R.storyboard.appStoryboard.pricingViewController() else { return }
        finalizingViewController = vc
        
        class ActionFinalizingDataSource: AppUIActionFinalizationViewControllerDataSource {
            private var app: App.Type?
            convenience init(app: App.Type?) {
                self.init()
                self.app = app
            }
            
            func titleForAction(in controller: AppUIActionFinalizationViewController) -> String? {
                return "Processing".localized
            }
            
            func imageForAction(in controller: AppUIActionFinalizationViewController) -> UIImage? {
                return nil
            }
        }
        
        vc.delegate = self
        vc.dataSource = ActionFinalizingDataSource(app: app)
        vc.setActionFinalizationItems([
            ActionFinalizationItem(image: UIImage(named: app.info.iconBundleName ?? "")?.rounded(), description: app.info.displayName),
            ActionFinalizationItem(title: nil, description: formattedStringForSelectedPhotos)
        ])
        self.present(vc, animated: true, completion: nil)
        
        setNavigationControllerDisabled(true)
    }

    private func showAndRevertTitleByCurrentAppIfNeeded(){
        let timerId = "picker_title_change_timer"
        if self.selectedAssetsInCollectionView?.count ?? 0 == 0 {
            let defaultTitle = self.collection?.localizedTitle ?? Bundle.main.displayName
            let revertingTitle = self.title == defaultTitle ? self.title : defaultTitle
            self.titleFade = AppCenter.default.current?.info.displayName
            Timer.scheduledTimer(identifier: timerId, withTimeInterval: 2, repeats: false) { timer in
                if self.selectedAssetsInCollectionView?.count ?? 0 == 0{
                    self.titleFade = revertingTitle
                }
            }
        }else{
            Timer.getScheduledTimer(identifier: timerId)?.invalidate()
        }
    }

    func redisplayVisibleCells() {
        AppAssets.selected.reloadAll()
        redisplayVisibleCellsEnabled()
        appDockView?.reloadKeepingDrawerOpened()
    }

    func redisplayVisibleCellsEnabled(){
        deselectCollectionViewItems(self.photoCollectionView.indexPathsForSelectedItems?.filter({ !collectionView(self.photoCollectionView, shouldSelectItemAt: $0) }) ?? [])
        updateVisibleCellsEnabled()
    }

    func updateUIDisplays() {
        updateSelectedItemsTitle()
        updateControlsReadyingToPerform()
    }

    //TODO: mod for all media types - numberOfPhotos + numberOfVideos
    private func updateSelectedItemsTitle() {
        title = formattedStringForNumberOfSelectedItems ?? (self.collection?.localizedTitle ?? Bundle.main.displayName)
    }
    
    private var formattedStringForNumberOfSelectedItems: String? {
        let selectedAssets = self.selectedAssetsInCollectionView
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfPhotos = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        let numberOfItems = numberOfPhotos + numberOfVideos
        
        if numberOfItems == 0 {
            return nil
        }
        else {
            if numberOfPhotos > 0 && numberOfVideos == 0 {
                let pluralizedString = "Photo" + (numberOfPhotos == 1 ? "" : "s")
                return "%d \(pluralizedString)".localizedFormatted(numberOfPhotos.decimalStyleString)
            }
            else if numberOfVideos > 0 && numberOfPhotos == 0 {
                let pluralizedString = "Video" + (numberOfVideos == 1 ? "" : "s")
                return "%d \(pluralizedString)".localizedFormatted(numberOfVideos.decimalStyleString)
            }
            else {
                let pluralizedString = "Item" + (numberOfItems == 1 ? "" : "s")
                return "%d \(pluralizedString)".localizedFormatted(numberOfItems.decimalStyleString)
            }
        }
    }

    private func updateControlsReadyingToPerform() {

        //update done button
        if AppCenter.default.current == nil{
            doneButton?.isEnabled = false
            doneButton?.title = nil
        }else{
            doneButton?.isEnabled = true

            let definedTitle = AppCenter.default.currentInstanceAs(PhotoPickerViewControllerDelegatableApp.self)?.doneButtonTitle
            doneButton?.title = definedTitle ?? "Start".localized
        }

        //update done execution state
        if updateDoneButtonChargeableState() {
            navigationItem.setLeftBarButton(self.cancelButton, animated: true)

            if appDockView?.accessory == nil {
                appDockView?.accessory = batchPreviewView
            }
        }else {
            navigationItem.setLeftBarButton(nil, animated: true)

            if appDockView?.accessory != nil {
                appDockView?.accessory = nil
                batchPreviewView.reloadContent()
            }
        }
    }

    var estimatedAvailableSelectedItems:Int{
        let selectedAssets = self.selectedAssetsInCollectionView
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfPhotos = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        return numberOfPhotos + numberOfVideos
    }

    var formattedStringForAllPhotos: String {
        var numberOfImages = 0
        var numberOfVideos = 0

        PHAssets.fetched.results?.forEach { fetchResult in
            numberOfImages += fetchResult.countOfAssets(with: PHAssetMediaType.image)
            numberOfVideos += fetchResult.countOfAssets(with: PHAssetMediaType.video)
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var footerText = ""
        if numberOfImages > 0 {
            if numberOfImages == 1 {
                footerText += "%d Photo".localizedFormatted(numberOfImages.decimalStyleString)
            }
            else {
                footerText += "%d Photos".localizedFormatted(numberOfImages.decimalStyleString)
            }
        }

        if numberOfVideos > 0 {
            if numberOfImages > 0 {
                footerText += ", "
            }

            if numberOfVideos == 1 {
                footerText += "%d Video".localizedFormatted(numberOfVideos.decimalStyleString)
            }
            else {
                footerText += "%d Videos".localizedFormatted(numberOfVideos.decimalStyleString)
            }
        }

        return footerText
    }
    
    private var formattedStringForSelectedPhotos: String? {
        let selectedAssets = self.selectedAssetsInCollectionView
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfImages = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        var text = ""
        if numberOfImages > 0 {
            if numberOfImages == 1 {
                text += "%d Photo".localizedFormatted(numberOfImages.decimalStyleString)
            }
            else {
                text += "%d Photos".localizedFormatted(numberOfImages.decimalStyleString)
            }
        }
        
        if numberOfVideos > 0 {
            if numberOfImages > 0 {
                text += ", "
            }
            
            if numberOfVideos == 1 {
                text += "%d Video".localizedFormatted(numberOfVideos.decimalStyleString)
            }
            else {
                text += "%d Videos".localizedFormatted(numberOfVideos.decimalStyleString)
            }
        }
        
        return text.isEmpty ? nil : text
    }
    
    private func updateAllPhotosTitle() {
        if let footer = self.photoCollectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? PhotoPickerFooterView {
            footer.text = self.formattedStringForAllPhotos
        }
    }

    func updateVisibleCellsEnabled() {
        for indexPath in photoCollectionView.indexPathsForVisibleItems{
            let cell = photoCollectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell
            cell?.isEnabled = collectionView(photoCollectionView, shouldSelectItemAt: indexPath)
        }
    }

    private func arePhotoLibraryChangesInCurrentFetched(_ changeInstance: PHChange) -> [(Int, PHFetchResultChangeDetails<PHAsset>)]?{
        guard let fetchResults = PHAssets.fetched.results else {
            return nil
        }

        let fetchResultChanges = fetchResults.enumerated().compactMap { results -> (Int, PHFetchResultChangeDetails<PHAsset>)? in
            let (section, result) = results
            if let details = changeInstance.changeDetails(for: result){
                return (section, details)
            }
            return nil
        }

        guard !fetchResultChanges.isEmpty else {
            return nil
        }

        return fetchResultChanges
    }

    @discardableResult
    private func photoLibraryDidChangeInCurrentFetched(_ changeInstance: PHChange) -> (inserted:[PHAsset],changed:[PHAsset],removed:[PHAsset])? {
        guard let fetchResultChanges = arePhotoLibraryChangesInCurrentFetched(changeInstance), !fetchResultChanges.isEmpty else {
            return nil
        }

        /*
            Handle Tasks while batch performing
        */
        let removedAssets = fetchResultChanges.compactMap { (_, changes) in changes.removedObjects}.reduce([],+)
        let changedAssets = fetchResultChanges.compactMap { (_, changes) in changes.insertedObjects}.reduce([],+)
        let insertedAssets = fetchResultChanges.compactMap { (_, changes) in changes.changedObjects}.reduce([],+)

        let tasksWereRanAndRemoved = AppCenter.default.task.isRunning && removedAssets.count > 0
        if tasksWereRanAndRemoved {
            AppCenter.default.task.suspend()

            for removedAsset in removedAssets{
                //delete task item
                if let appTaskItem = AppCenter.default.task.currentTaskItems.first(where:{ item in
                    (item.request.param as? AppAsset)?.asset.localIdentifier==removedAsset.localIdentifier
                }){
                    AppCenter.default.task.remove(request: appTaskItem.request)
                }
            }
        }

        //remove preview items
        self.batchPreviewView.removeCollectionViewItems(with: removedAssets)
        
        var indexPathToScroll: IndexPath?
        var needsToRestoreSelection = false
        var insertedIndexes = [IndexPath]()

        //perform batch update
        //confirm and remove: https://console.firebase.google.com/project/batch-photos/crashlytics/app/ios:com.stells.pap/issues/5ac8295036c7b23527c249dd?time=1523145600000:1523231999000&sessionId=18f49e20db084ed8b9c8b26e72871bad_DNE_0_v2
        self.photoCollectionView.performBatchUpdates({
            for (section, changes) in fetchResultChanges {
                // Update data collection before items updated
                if false == PHAssets.fetched.update(result: changes.fetchResultAfterChanges, at: section){
                    assert(false, "section is changed but didn't collected.")
                    continue
                }

                // Reload the collection view if incremental diffs are not available.
                if false == (changes.hasIncrementalChanges || changes.hasMoves) {
                    self.photoCollectionView.reloadData()
                    break
                }

                // If there are incremental diffs, animate them in the collection view.
                // For indexes to make sense, updates must be in this order:
                // delete, insert, reload, move
                var removedIndexPaths: [IndexPath]?
                if let removed = changes.removedIndexes, removed.count > 0 {
                    let indexPaths = removed.map { IndexPath(item: $0, section:section) }
                    needsToRestoreSelection = true
                    self.photoCollectionView.deleteItems(at: indexPaths)
                    
                    if PHAssets.fetched.results?[section].count == 0 {
                        self.photoCollectionView.reloadSections(IndexSet(integer: section))
                    }
                    
                    removedIndexPaths = indexPaths
                }
                if let inserted = changes.insertedIndexes, inserted.count > 0 {
                    let indexPaths = inserted.map { IndexPath(item: $0, section:section) }
                    indexPathToScroll = indexPaths.last
                    needsToRestoreSelection = true

                    insertedIndexes.append(contentsOf: indexPaths)
                    self.photoCollectionView.insertItems(at: indexPaths)
                }
                if let changed = changes.changedIndexes, changed.count > 0 {
                    let indexPaths = changed.map { IndexPath(item: $0, section:section) }
                    self.photoCollectionView.reloadItems(at: indexPaths.filter { removedIndexPaths?.contains($0) != true })
                }
                changes.enumerateMoves { fromIndex, toIndex in
                    needsToRestoreSelection = true
                    self.photoCollectionView.moveItem(at: IndexPath(item: fromIndex, section: section), to: IndexPath(item: toIndex, section: section))
                }
            }
        }, completion: { _ in
            if tasksWereRanAndRemoved {
                AppCenter.default.task.perform(self.batchPreviewView.createTaskReaction())
                papLog.performWhenPhotoLibraryDidChanged()
            }else{
                self.updateAllPhotosTitle()
                self.updateUIDisplays()
            }
            
            if let indexPathToScroll = indexPathToScroll {
                //TODO: test for scroll inserted items instead of restore previous selections
                self.photoCollectionView.scrollToItem(at: indexPathToScroll, at: UICollectionViewScrollPosition.bottom, animated: true)
            }
            
            if needsToRestoreSelection {
                let selectedAssetIdentifiers = self.photoCollectionView.indexPathsForSelectedItems?.compactMap({ PHAssets.fetched.asset(at: $0)?.localIdentifier })
                self.restoreSelectionByUser(selectedAssetIdentifiers)
            }
            
            self.appDockView?.reloadKeepingDrawerOpened()

            // PhotoPickerCollectionViewDisplayableApp.shouldSelectWhenInserted
            let collectionViewDelegatableApp = AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewDisplayableApp.self)
            if let allowedSelectionIndexPaths = collectionViewDelegatableApp?.shouldSelectWhenInserted(indexPaths: insertedIndexes.nilEmpty){
                Timer.scheduledTimer(identifier: #file+#function, withTimeInterval: 0) { timer in
                    for indexPath in allowedSelectionIndexPaths {
                        self.selectCollectionViewItem(at: indexPath)
                    }

                    DispatchQueue.mainAsyncAfter(qos: .background) {
                        self.viewDidLayoutSubviews()
                        self.setNeedsScrollToBottom()
                        self.scrollToBottomIfNeeded(animated: true)
                    }
                }
            }
        })

        return (inserted: insertedAssets, changed:changedAssets, removed:removedAssets)
    }
}

extension UIView {
    func asImage() -> UIImage? {
        return UIGraphicsImageRenderer(bounds: bounds).imageWithCurrentContext { [weak self] (ctx) in
            self?.layer.render(in: ctx)
        }
    }
}

extension PhotoPickerViewController: EditViewControllerDelegate {
    func showPhotoEditor(with editItem: AppAsset?) {
        guard let editItem = editItem else { return }
        
        if let photoEditViewController = R.storyboard.appStoryboard.photoEditViewController(){
            photoEditViewController.preferredEditState = editItem.editState
            photoEditViewController.asset = editItem.asset
            photoEditViewController.delegate = self
            photoEditViewController.indexPathInPicker = PHAssets.fetched.indexPath(of:editItem.asset)
            photoEditViewController.selectedInPicker = AppAssets.selected.by(editItem.asset) != nil
            
            if let index = AppAssets.selected.index(of: editItem), let cell = batchPreviewView.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? PreviewCollectionViewCell {
                let snapshot = cell.assetView.asImage()?.applyTransform(editItem.editState.transform)
                photoEditViewController.placeholderImage = snapshot
                
                let placeholderView = UIImageView(frame: cell.assetView.frame)
                placeholderView.image = snapshot
                placeholderView.contentMode = .scaleAspectFit
                placeholderView.hero.id = "TransitionToPhotoEditViewController"
                cell.assetView.superview?.addSubview(placeholderView)
                
                photoEditorTransitionContext = PhotoEditorTransitionContext(sourceView: cell.assetView, placeholderView: placeholderView)
                photoEditorTransitionContext?.sourceView.isHidden = true
            }
            else if let indexPath = photoEditViewController.indexPathInPicker, let cell = photoCollectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
                let snapshot = editItem.asset.requestThumbnailImage(targetSize: cell.imageView.frame.size)
                photoEditViewController.placeholderImage = snapshot
                
                let placeholderView = UIImageView(frame: cell.imageView.frame)
                placeholderView.image = snapshot
                placeholderView.contentMode = .scaleAspectFill
                placeholderView.hero.id = "TransitionToPhotoEditViewController"
                cell.imageView.superview?.addSubview(placeholderView)
                
                photoEditorTransitionContext = PhotoEditorTransitionContext(sourceView: cell.imageView, placeholderView: placeholderView)
                photoEditorTransitionContext?.sourceView.isHidden = true
            }

            let navigationController = AppDockNavigationController(rootViewController: photoEditViewController)
            navigationController.hero.isEnabled = true
            navigationController.hero.modalAnimationType = .fade
            navigationController.hero.navigationAnimationType = .fade
            
            present(navigationController, animated: true) {
                self.photoEditorTransitionContext?.sourceView.isHidden = false
                
                AppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues(AppConfigUIAttribute(tintColor: .white))
            }
        }
    }

    func editViewController(_ photoEditor: PhotoEditViewController, didFinishWith editItem: StateValueSet<ImageEditStateValue>?, at indexPath: IndexPath?) {
        assert(photoEditor.asset != nil, "photoEditor.asset!=nil")
        
        guard let asset = photoEditor.asset else { return }

        if let indexPath = indexPath {
            if let editItem = editItem, editItem.hasChanges {
                if AppAssets.selected.by(asset) == nil{
                    self.selectCollectionViewItem(at: indexPath, animated: false)
                }
                assert(AppAssets.selected.by(photoEditor.asset!) != nil, "AppAssets.selected.by(photoEditor.asset!) != nil")
                AppAssets.selected.by(asset)?.editState.concat(with: editItem)
            }
        }

        let tintColorToRestore = ((AppCenter.default.current as? ConfigurableApp.Type)?.defaultConfigValue as? AppConfigUIAttributeValuable)?.tintColor

        AppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues(AppConfigUIAttribute(tintColor: tintColorToRestore))
        
        if let transitionContext = photoEditorTransitionContext {
            transitionContext.placeholderView.frame.origin = transitionContext.sourceView.frame.origin
            
            if let editItem = editItem {
                if let filter = editItem.ciFilter {
                    transitionContext.placeholderView.image = photoEditor.originalImage?.applyFilter(ciFilter: filter)
                }
                
                transitionContext.placeholderView.transform = editItem.transform
            }
        }
        
        photoEditorTransitionContext?.sourceView.isHidden = true
        batchPreviewView.reloadCollectionViewItems(animated: false)
        
        photoEditor.dismiss(animated: true, completion: {
            self.photoEditorTransitionContext?.sourceView.isHidden = false
            self.photoEditorTransitionContext?.placeholderView.removeFromSuperview()
            self.photoEditorTransitionContext = nil
        })
    }
}

extension PhotoPickerViewController: PreviewViewDelegate {
    var currentDisplayableApp: PhotoPickerViewControllerDelegatableApp?{
        if AppCenter.default.current is PhotoPickerViewControllerDelegatableApp.Type{
            return AppCenter.default.currentInstanceAs(PhotoPickerViewControllerDelegatableApp.self)
        }
        return nil
    }

    func batchPreviewView(_ view: PreviewView, didSelectItemAt indexPath: IndexPath) {
        let selectedAssetItem = AppAssets.selected.at(indexPath.item)
        
        if let _ = AppCenter.default.currentInstanceAs(PhotoEditorViewControllerDelegatableApp.self), appDockView?.contentLayoutState == .maximized {
            showPhotoEditor(with: selectedAssetItem)
        }
        else {
            guard let indexPathInPhotoPicker = PHAssets.fetched.indexPath(of: selectedAssetItem.asset) else { return }
            photoCollectionView.scrollToItem(at: indexPathInPhotoPicker, at: .centeredVertically, animated: true)
        }
    }
    
    func batchPreviewViewWillBeginEdit(_ view: PreviewView) {
        taskProgress = 0

        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingIndicator), animated: true)
        
        finalizingViewController?.actionProgressDidBegin(actionTitle: currentDisplayableApp?.titleWillBegin ?? "Starting the Process...".localized)
    }
    
    private func updateProgress(_ progress: Float, title: String, animated: Bool = true) {
        let progress = progress.clamped(to: 0...1)
        let progressText = currentDisplayableApp?.titleDidUpdate(progress: progress)
            ?? title + " \(Int(progress * 100))%"
        
        finalizingViewController?.actionProgressDidUpdate(actionTitle: progressText, progress: progress)
    }
    
    func batchPreviewView(_ view: PreviewView, didUpdateProgress progress: Float) {
        if let progressView = finalizingViewController?.actionProgressView, progressView.progress < progress {
            taskProgress = progress
            updateProgress(progress, title: "Processing...".localized)
        }
    }
    
    func batchPreviewView(_ view: PreviewView, didUpdateRemoteFetchingProgress progress: Float) {
        guard AppAssets.selected.count > 0 else { return }
        let fetchingProgressPerTask = progress / Float(AppAssets.selected.count)
        let currentProgress = taskProgress + fetchingProgressPerTask / 2 // for split progress into fetching and processing
        if let progressView = finalizingViewController?.actionProgressView, progressView.progress < currentProgress {
            updateProgress(currentProgress, title: "Downloading...".localized)
        }
    }
    
    func batchPreviewView(_ view: PreviewView, didUpdateInternalProgress progress: Float) {
        guard AppAssets.selected.count > 0 else { return }
        
        let fetchingProgressPerTask = progress / Float(AppAssets.selected.count)
        let currentProgress = taskProgress + fetchingProgressPerTask / 2 // for split progress into fetching and processing
        if let progressView = finalizingViewController?.actionProgressView, progressView.progress < currentProgress {
            updateProgress(currentProgress, title: "Processing...".localized)
        }
    }

    func batchPreviewViewWillCancelProgress(_ view: PreviewView) {
        finalizingViewController?.actionProgressDidBegin(actionTitle: currentDisplayableApp?.titleWillCancel ?? "Cancelling...".localized)
    }

    func batchPreviewViewWillFinalize(_ view: PreviewView) {
        finalizingViewController?.actionProgressDidFinish(actionTitle: currentDisplayableApp?.titleWillFinalize ?? "Saving Results...".localized)
    }
    
    func batchPreviewViewDidCancelEdit(_ view: PreviewView) {
        updateAllPhotosTitle()
        updateUIDisplays()
        updateVisibleCellsEnabled()
        
        finalizingViewController?.close()
    }
    
    func batchPreviewViewDidEndEdit(_ view: PreviewView) {
        //POLICY: no keeps selected items
        deselectAllCollectionViewItems()

        updateAllPhotosTitle()
        updateUIDisplays()
        updateVisibleCellsEnabled()
        
        finalizingViewController?.close()
        
        //POLICY: add recently used shortcut item
        ShortcutItemAppDelegate.appendShortcutItem(by: AppCenter.default.current)
    }
}

extension PhotoPickerViewController: AppUIActionFinalizationViewControllerDelegate {
    func actionFinalizationViewControllerDidAction(_ controller: AppUIActionFinalizationViewController) {
        
    }
    
    func actionFinalizationViewControllerDidClose(_ controller: AppUIActionFinalizationViewController) {
        setNavigationControllerDisabled(false)
    }
    
    func actionFinalizationViewControllerDidCancel(_ controller: AppUIActionFinalizationViewController) {
        if AppCenter.default.task.isRunning {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
            cancelPreheatingIfNeeded()
            
            cancelProcessing()
        }
        
        controller.close()
    }
}

extension PhotoPickerViewController: AppDockViewDelegate{
    func appDockView(_ view: AppDockView, needsScrollToBottom: Bool) {
        self.needsScrollToBottom = needsScrollToBottom
    }

    func appDockView(_ view: AppDockView, didSelectItemWith item: AppDockItem) {
        let willAppChange = AppCenter.default.current != item.app

        AppCenter.default.current = item.app

        view.loadControllerContentIfNeeded()

        if willAppChange {
            appDidChange()
        }
        else {
            if photoCollectionView.contentOffset.y >= self.scrollingBottomOffsetY{
                if appDockView?.contentLayoutState == .minimized {
                    appDockView?.openDrawer()
                }
            }
            else {
                scrollToBottomIfNeeded(animated: true)
            }
        }
    }

    func appDockView(_ view: AppDockView, didOpenDrawer isOpened: Bool) {
        setViewControllerDisabled(isOpened)
    }
}

// MARK: - Photos

