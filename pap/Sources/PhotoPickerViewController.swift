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

extension PhotoPickerViewController {
    var kPhotoPickerNumberOfItemsInRow: CGFloat { return 4 }
}

class PhotoPickerViewController: AppDockViewController {
    @IBOutlet weak var photoCollectionView: UICollectionView!
    var initialPhotoCollectionIndexPath: IndexPath?
    
    var batchPreviewView: PreviewView!
    private var appDockDrawerLayoutModeRestoringAfterProcessing: DrawerLayoutMode?
    
    var progressBar: UIProgressView!
    private var taskProgress: Float = 0

    var dragSelectionGesture: DragSelectionGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //preview
        batchPreviewView = PreviewView(frame: .zero)
        batchPreviewView.delegate = self

        //photos collection
        photoCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: PhotoCollectionViewCell.self))
        photoCollectionView.register(PhotoPickerSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoPickerSectionHeaderView")
        photoCollectionView.register(PhotoPickerFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "PhotoPickerFooterView")
        photoCollectionView.allowsMultipleSelection = true
        
        //peek and pop
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: photoCollectionView)  // self here is UIViewController type, and view is property of UIViewController
            registerForPreviewing(with: self, sourceView: batchPreviewView)
        }

        //photos access authorization
        PHPhotoLibraryManager.default.watch(\.changes) {
            guard let changeInstance = PHPhotoLibraryManager.default.changes else { return }

            DispatchQueue.main.async {
                self.photoLibraryDidChange(changeInstance)
            }
        }

        PHPhotoLibraryManager.default.authorizeIfNeeded { authorized in
            guard authorized else { return }
            
            PHAssets.fetched.unload()
            PHAssets.fetched.load(with: .smartAlbum, subtype: self.collectionViewDisplayableApp?.conformsAssetCollectionType ?? .smartAlbumUserLibrary, mediaType: self.collectionViewDisplayableApp?.conformsMediaType) // iphone x: .028702974319458s
            
            if let numberOfSection = PHAssets.fetched.results?.count, numberOfSection > 0
                , let numberOfItemsInSection = PHAssets.fetched.results?[numberOfSection - 1].count
                , numberOfItemsInSection > 0 {
                
                self.initialPhotoCollectionIndexPath = IndexPath(item: numberOfItemsInSection - 1, section: numberOfSection - 1)
            }
            self.photoCollectionView.reloadData()

            //PHAssets.fetched.results?.first?.enumerateObjects { asset, i, pointer in }
         }

        //navigation controller accessories
        title = Bundle.main.displayName

        navigationItem.setLeftBarButton(nil, animated: false)
        navigationItem.setRightBarButton(nil, animated: false)

        //navigation bar progress
        if let navigationVC = self.navigationController {
            progressBar = UIProgressView(progressViewStyle: .bar)
            progressBar.isHidden = false

            navigationVC.navigationBar.addSubview(progressBar)

            let bottomConstraint = NSLayoutConstraint(item: navigationVC.navigationBar, attribute: .bottom, relatedBy: .equal, toItem: progressBar, attribute: .bottom, multiplier: 1, constant: 1)
            let leftConstraint = NSLayoutConstraint(item: navigationVC.navigationBar, attribute: .leading, relatedBy: .equal, toItem: progressBar, attribute: .leading, multiplier: 1, constant: 0)
            let rightConstraint = NSLayoutConstraint(item: navigationVC.navigationBar, attribute: .trailing, relatedBy: .equal, toItem: progressBar, attribute: .trailing, multiplier: 1, constant: 0)

            progressBar.translatesAutoresizingMaskIntoConstraints = false
            navigationVC.view.addConstraints([bottomConstraint, leftConstraint, rightConstraint])
        }
        
        dragSelectionGesture = DragSelectionGestureRecognizer(target: self, action: #selector(self.dragSelectionGestureDidRecognize))
        dragSelectionGesture.delegate = self
        photoCollectionView.addGestureRecognizer(dragSelectionGesture)
    }

    func redisplayCurrentVisibleCellsWhenUpdateApps() {
        AppAssets.selected.reloadAll()
        self.redisplayVisibleCellsWhenChangeApp()
        self.batchPreviewView.updatePreviews()
    }
    
    override func registerWatchingAppConfig() {
        AppCenter.default.watch(\.currentIdentifier, options:[.new, .old, .initial]) { (appCenter, dict) in
            let old = dict.oldValue
            let new = dict.newValue
            
            if old != nil && new != nil && old != new {
                AppAssets.selected.reloadAll()
                self.redisplayVisibleCellsWhenChangeApp()
                self.showAndRevertTitleByCurrentAppIfNeeded()
            }

            self.updateDoneButtonState()

            AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"picker\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform, !AppCenter.default.isAppRunning{
                    self.setAppValue(value)
                }
            }
            
            AppCenter.default.currentInstanceAs(PhotosFilterApp.self)?.config?.watch(\.filter, id:"picker\(PhotosFilterApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.isAppRunning{
                    self.setAppValue(value)
                }
            }
            
            AppCenter.default.currentInstanceAs(AutoAdjustmentApp.self)?.config?.watch(\.filter, id:"picker\(AutoAdjustmentApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.isAppRunning{
                    self.setAppValue(value)
                }
            }
            
            AppCenter.default.currentInstanceAs(Stabilizer.self)?.config?.watch(\.stabilizationMode, id:"picker\(Stabilizer.info.identifier)") { (config, changed) in
                if let value = config.stabilizationMode, !AppCenter.default.isAppRunning{
                    self.setAppValue(value)
                }
            }

            AppCenter.default.currentInstanceAs(GIFMaker.self)?.config?.watch(\.sourceType, id:"picker\(GIFMaker.info.identifier)") { (config, changed) in
                self.redisplayCurrentVisibleCellsWhenUpdateApps()
            }

            AppCenter.default.currentInstanceAs(ConvertApp.self)?.config?.watch(\.convertingDirectionIdentifier, id:"picker\(ConvertApp.info.identifier)") { (config, changed) in
                self.redisplayCurrentVisibleCellsWhenUpdateApps()
            }
        }
    }
    
    private func setAppValue(_ value: ImageEditStateValue) {
        AppAssets.selected.appendValue(value)
        
        batchPreviewView.updatePreviews()
    }
    
    override func unregisterWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["picker\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(PhotosFilterApp.self)?.config?.unwatch(\.filter, forIds:["picker\(PhotosFilterApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(AutoAdjustmentApp.self)?.config?.unwatch(\.filter, forIds:["picker\(AutoAdjustmentApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(Stabilizer.self)?.config?.unwatch(\.stabilizationMode, forIds:["picker\(Stabilizer.info.identifier)"])
        AppCenter.default.currentInstanceAs(GIFMaker.self)?.config?.unwatch(\.sourceType, forIds:["picker\(GIFMaker.info.identifier)"])
        AppCenter.default.currentInstanceAs(ConvertApp.self)?.config?.unwatch(\.convertingDirectionIdentifier, forIds:["picker\(ConvertApp.info.identifier)"])

        AppCenter.default.unwatchAllFilePrivate(\.currentIdentifier)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        photoCollectionView.contentInset.bottom = appDockInsets.bottom
        photoCollectionView.scrollIndicatorInsets.bottom = photoCollectionView.contentInset.bottom
    }
    
    override func cancelButtonDidTap(sender: Any) {
        super.cancelButtonDidTap(sender: sender)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        cancelAllInCurrentContext()
    }
    
    override func doneButtonDidTap(sender: Any) {
        super.doneButtonDidTap(sender: sender)
        
        batchPreviewView.runBatchProcessing()
        
        updateVisiblePhotoCollectionCellsEnabled()
    }

    private func showAndRevertTitleByCurrentAppIfNeeded(){
        let timerId = "picker_title_change_timer"
        if self.selectedAssetsInCollectionView?.count ?? 0 == 0 {
            let revertingTitle = self.title == Bundle.main.displayName ? self.title : Bundle.main.displayName
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

    func redisplayVisibleCellsWhenChangeApp(){
        deselectCollectionViewItems(self.photoCollectionView.indexPathsForSelectedItems?.filter({ !collectionView(self.photoCollectionView, shouldSelectItemAt: $0) }) ?? [IndexPath]())
        updateVisiblePhotoCollectionCellsEnabled()
        
        refetchAssets()
    }
    
    func refetchAssets() {
        let collectionSubtype = collectionViewDisplayableApp?.conformsAssetCollectionType ?? .smartAlbumUserLibrary
        let mediaType = collectionViewDisplayableApp?.conformsMediaType
        
        guard PHAssets.fetched.collectionSubtype != collectionSubtype || PHAssets.fetched.mediaType != mediaType else { return }
        
        let selectedAssetIdentifiers = photoCollectionView.indexPathsForSelectedItems?.compactMap({ PHAssets.fetched.asset(at: $0)?.localIdentifier })
        
        PHAssets.fetched.unload()
        PHAssets.fetched.load(with: .smartAlbum, subtype: collectionSubtype, mediaType: mediaType) // iphone x: .028702974319458s
        
        if let numberOfSection = PHAssets.fetched.results?.count, numberOfSection > 0
            , let numberOfItemsInSection = PHAssets.fetched.results?[numberOfSection - 1].count
            , numberOfItemsInSection > 0 {
            
            self.initialPhotoCollectionIndexPath = IndexPath(item: numberOfItemsInSection - 1, section: numberOfSection - 1)
        }
        self.photoCollectionView.reloadData()
        self.photoCollectionView.layoutIfNeeded()
        
        self.restoreSelectionByUser(selectedAssetIdentifiers)
        
        self.updateSelectedItemUIs()
        
        self.appDockView?.reloadKeepingDrawerOpened()
    }

    func updateSelectedItemUIs() {
        updateSelectedItemsTitle()
        updateSelectedItemsControl()
        updateDoneButtonState()
    }

    //TODO: mod for all media types - numberOfPhotos + numberOfVideos
    private func updateSelectedItemsTitle() {
        let selectedAssets = self.selectedAssetsInCollectionView
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfPhotos = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        let numberOfItems = numberOfPhotos + numberOfVideos

        if numberOfItems == 0 {
            title = Bundle.main.displayName
        }
        else {
            if numberOfPhotos > 0 && numberOfVideos == 0 {
                let pluralizedString = "Photo" + (numberOfPhotos == 1 ? "" : "s")
                title = "%d \(pluralizedString)".localizedFormatted(numberOfPhotos.decimalStyleString)
            }
            else if numberOfVideos > 0 && numberOfPhotos == 0 {
                let pluralizedString = "Video" + (numberOfVideos == 1 ? "" : "s")
                title = "%d \(pluralizedString)".localizedFormatted(numberOfVideos.decimalStyleString)
            }
            else {
                let pluralizedString = "Item" + (numberOfItems == 1 ? "" : "s")
                title = "%d \(pluralizedString)".localizedFormatted(numberOfItems.decimalStyleString)
            }
        }
    }

    private func updateSelectedItemsControl() {
        let selectedAssets = self.selectedAssetsInCollectionView
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfPhotos = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        let numberOfItems = numberOfPhotos + numberOfVideos
        
        if numberOfItems == 0 {
            navigationItem.setLeftBarButton(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)
            
            if appDockView?.accessory != nil {
                appDockView?.accessory = nil
            }
        }
        else {
            navigationItem.setLeftBarButton(self.cancelButton, animated: true)
            navigationItem.setRightBarButton(self.doneButton, animated: true)

            if appDockView?.accessory == nil {
                appDockView?.accessory = batchPreviewView
            }
        }
    }

    private func updateDoneButtonState() {

        if AppCenter.default.current == nil{
            doneButton?.isEnabled = false
            doneButton?.title = nil
        }else{
            doneButton?.isEnabled = true

            let definedTitle = AppCenter.default.currentInstanceAs(PhotoPickerViewControllerDelegatableApp.self)?.doneButtonTitle
            doneButton?.title = definedTitle ?? "Start".localized
        }
    }
    
    func formattedStringForAllPhotos(at section: Int) -> String {
        var numberOfImages = 0
        var numberOfVideos = 0
        
        if let fetchResult = PHAssets.fetched.results?[safe: section] {
            numberOfImages += fetchResult.countOfAssets(with: PHAssetMediaType.image)
            numberOfVideos += fetchResult.countOfAssets(with: PHAssetMediaType.video)
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var formattedString = ""
        if numberOfImages > 0 {
            if numberOfImages == 1 {
                formattedString += "%d Photo".localizedFormatted(numberOfImages.decimalStyleString)
            }
            else {
                formattedString += "%d Photos".localizedFormatted(numberOfImages.decimalStyleString)
            }
        }

        if numberOfVideos > 0 {
            if numberOfImages > 0 {
                formattedString += ", "
            }

            if numberOfVideos == 1 {
                formattedString += "%d Video".localizedFormatted(numberOfVideos.decimalStyleString)
            }
            else {
                formattedString += "%d Videos".localizedFormatted(numberOfVideos.decimalStyleString)
            }
        }

        return formattedString
    }
    
    private func updateAllPhotosTitle() {
        for section in 0..<(PHAssets.fetched.results?.count ?? 0) {
            guard let footer = self.photoCollectionView.supplementaryView(forElementKind: UICollectionElementKindSectionFooter, at: IndexPath(item: 0, section: section)) as? PhotoPickerFooterView else { continue }
            footer.text = formattedStringForAllPhotos(at: section)
        }
    }

    func updateVisiblePhotoCollectionCellsEnabled() {
        for indexPath in photoCollectionView.indexPathsForVisibleItems{
            let cell = photoCollectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell
            cell?.isEnabled = collectionView(photoCollectionView, shouldSelectItemAt: indexPath)
        }
    }

    private func photoLibraryDidChange(_ changeInstance: PHChange) {
        let selectedAssetIdentifiers = photoCollectionView.indexPathsForSelectedItems?.compactMap({ PHAssets.fetched.asset(at: $0)?.localIdentifier })
        
        guard let fetchResults = PHAssets.fetched.results else { return }

        let fetchResultChanges = fetchResults.enumerated().compactMap { results -> (Int, PHFetchResultChangeDetails<PHAsset>)? in
            let (section, result) = results
            if let details = changeInstance.changeDetails(for: result){
                return (section, details)
            }
            return nil
        }
        
        guard !fetchResultChanges.isEmpty else { return }

        /*
            Handle Tasks while batch performing
        */
        let removedAssets = fetchResultChanges.compactMap { (_, changes) in changes.removedObjects}.reduce([],+)
        let tasksWereRanAndRemoved = AppCenter.default.isAppRunning && removedAssets.count > 0
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
        for removedAsset in removedAssets{
            self.batchPreviewView.removeCollectionViewItem(with: removedAsset)
        }
        
        var indexPathToScroll: IndexPath?
        var needsToRestoreSelection = false

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
                if let removed = changes.removedIndexes, removed.count > 0 {
                    let indexPaths = removed.map { IndexPath(item: $0, section:section) }
                    needsToRestoreSelection = true
                    self.photoCollectionView.deleteItems(at: indexPaths)
                    
                    if PHAssets.fetched.results?[section].count == 0 {
                        self.photoCollectionView.reloadSections(IndexSet(integer: section))
                    }
                }
                if let inserted = changes.insertedIndexes, inserted.count > 0 {
                    let indexPaths = inserted.map { IndexPath(item: $0, section:section) }
                    indexPathToScroll = indexPaths.last
                    needsToRestoreSelection = true
                    
                    self.photoCollectionView.insertItems(at: indexPaths)
                }
                if let changed = changes.changedIndexes, changed.count > 0 {
                    self.photoCollectionView.reloadItems(at: changed.map { IndexPath(item: $0, section:section) })
                }
                changes.enumerateMoves { fromIndex, toIndex in
                    needsToRestoreSelection = true
                    self.photoCollectionView.moveItem(at: IndexPath(item: fromIndex, section: section), to: IndexPath(item: toIndex, section: section))
                }
            }
        }, completion: { _ in
            if tasksWereRanAndRemoved {
                AppCenter.default.task.perform(self.batchPreviewView.createTaskReaction())
            }else{
                self.updateAllPhotosTitle()
                self.updateSelectedItemUIs()
            }
            
            if let indexPathToScroll = indexPathToScroll {
                //TODO: test for scroll inserted items instead of restore previous selections
                self.photoCollectionView.scrollToItem(at: indexPathToScroll, at: UICollectionViewScrollPosition.bottom, animated: true)
            }
            
            if needsToRestoreSelection {
                self.restoreSelectionByUser(selectedAssetIdentifiers)
            }
            
            if self.appDockView?.isDrawerMaximized == true {
                self.appDockView?.closeDrawer(reloadDockContentViews: true)
            }
            else {
                self.appDockView?.reloadKeepingDrawerOpened()
            }
            self.batchPreviewView.reloadContent()
        })
    }
    
    private func restoreSelectionByUser(_ assetLocalIdentifiers: [String]?) {
        guard let localIdentifiers = assetLocalIdentifiers else { return }
        PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil).enumerateObjects { (asset, idx, stop) in
            self.updateCollectionViewSelection(by: asset)
        }
    }
    
    private func deselectCollectionViewItems(with assetLocalIdentifiers: [String]?) {
        guard let localIdentifiers = assetLocalIdentifiers else { return }
        var indexPaths = [IndexPath]()
        PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil).enumerateObjects { (asset, idx, stop) in
            guard let indexPath = PHAssets.fetched.indexPath(of: asset) else { return }
            indexPaths.append(indexPath)
        }
        self.deselectCollectionViewItems(indexPaths)
    }
}

extension PhotoPickerViewController: EditViewControllerDelegate {
    func showPhotoEditor(with editItem: PHAssetItem<ImageEditStateValue>?) {
        guard let editItem = editItem else { return }

        if let photoEditViewController = R.storyboard.appStoryboard.photoEditViewController(){
            photoEditViewController.preferredEditState = editItem.editState
            photoEditViewController.asset = editItem.asset
            photoEditViewController.delegate = self
            photoEditViewController.indexPathInPicker = PHAssets.fetched.indexPath(of:editItem.asset)
            photoEditViewController.selectedInPicker = AppAssets.selected.by(editItem.asset) != nil

            let navigationController = AppDockNavigationController(rootViewController: photoEditViewController)
            present(navigationController,animated: true) {

                AppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .white))
            }
        }
    }

    func editViewController(_ photoEditor: PhotoEditViewController, didFinishWith editItem: StateValueSet<ImageEditStateValue>?, at indexPath: IndexPath?) {
        assert(photoEditor.asset != nil, "photoEditor.asset!=nil")

        if let indexPath = indexPath, let asset = photoEditor.asset {

            if let editItem = editItem, editItem.hasChanges {
                if AppAssets.selected.by(asset) == nil{
                    self.selectCollectionViewItem(at: indexPath, animated: false)
                }
                assert(AppAssets.selected.by(photoEditor.asset!) != nil, "AppAssets.selected.by(photoEditor.asset!) != nil")
                AppAssets.selected.by(asset)?.editState.concat(with: editItem)
            }
        }

        AppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .black))

        photoEditor.dismiss(animated: true, completion: {
            self.batchPreviewView.reloadCollectionViewItems()
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
        let selectedAsset = AppAssets.selected.at(indexPath.item).asset
        guard let indexPathInPhotoPicker = PHAssets.fetched.indexPath(of: selectedAsset) else { return }
        photoCollectionView.scrollToItem(at: indexPathInPhotoPicker, at: .centeredVertically, animated: true)
    }
    
    func batchPreviewViewWillBeginEdit(_ view: PreviewView) {
        titleFade = currentDisplayableApp?.titleWillBegin
                ?? "Start Batch Editing...".localized
        taskProgress = 0

        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingIndicator), animated: true)

        progressBar.isHidden = false
        progressBar.progress = 0
        UIView.animate(withDuration: 0.2) {
            self.progressBar.alpha = 1
        }
        
        updateAppDockViewProcessingStart()
    }
    
    private func updateProgress(_ progress: Float, title: String, animated: Bool = true) {
        let progressText = currentDisplayableApp?.titleDidUpdate(progress: progress)
            ?? title + " \(Int(progress * 100))%"
        
        if animated {
            titleFade = progressText
        }
        else {
            self.title = progressText
        }
        
        progressBar.setProgress(progress, animated: animated)
    }
    
    func batchPreviewView(_ view: PreviewView, didUpdateProgress progress: Float) {
        if progressBar.progress < progress {
            taskProgress = progress
            updateProgress(progress, title: "Processing...".localized)
        }
    }
    
    func batchPreviewView(_ view: PreviewView, didUpdateFetching progress: Float) {
        let fetchingProgressPerTask = progress / Float(AppAssets.selected.count)
        let currentProgress = taskProgress + fetchingProgressPerTask / 2 // for split progress into fetching and processing
        if progressBar.progress < currentProgress {
            updateProgress(currentProgress, title: "Downloading...".localized)
        }
    }
    
    func batchPreviewView(_ view: PreviewView, didUpdateProcessing progress: Float) {
        let fetchingProgressPerTask = progress / Float(AppAssets.selected.count)
        let currentProgress = taskProgress + fetchingProgressPerTask / 2 // for split progress into fetching and processing
        if progressBar.progress < currentProgress {
            updateProgress(currentProgress, title: "Processing...".localized)
        }
    }

    func batchPreviewViewWillCancelProgress(_ view: PreviewView) {
        titleFade = currentDisplayableApp?.titleWillCancel
                ?? "Cancelling...".localized

        UIView.animate(withDuration: 0.6) {
            self.progressBar.alpha = 0
        }
    }

    func batchPreviewViewWillFinalize(_ view: PreviewView) {
        titleFade = currentDisplayableApp?.titleWillFinalize
                ?? "Saving Photos...".localized

        UIView.animate(withDuration: 0.6) {
            self.progressBar.alpha = 0
        }
    }
    
    func batchPreviewViewDidEndEdit(_ view: PreviewView) {
        progressBar.isHidden = true

        updateSelectedItemUIs()
        updateVisiblePhotoCollectionCellsEnabled()
        
        updateAppDockViewProcessingEnd()
    }
    
    func batchPreviewViewDidCancelEdit(_ view: PreviewView) {
        // waiting for remaining processing
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.updateAllPhotosTitle()
        }

        progressBar.isHidden = true
        
        updateAppDockViewProcessingEnd()
    }
    
    private func updateAppDockViewProcessingStart() {
        appDockDrawerLayoutModeRestoringAfterProcessing = appDockView?.drawerLayoutMode
        appDockView?.minimizeDrawer(reloadDockContentViews: true)
        
        appDockView?.disabled = true
    }
    
    private func updateAppDockViewProcessingEnd() {
        if let layoutMode = appDockDrawerLayoutModeRestoringAfterProcessing {
            appDockView?.setDrawerLayoutMode(layoutMode, reloadDockContentViews: true)
            appDockDrawerLayoutModeRestoringAfterProcessing = nil
        }
        
        appDockView?.disabled = false
    }
    
    func batchPreviewView(_ view: PreviewView, didChangeAssets assets: PHFetchResult<PHAsset>) {
        if let insertedSection = PHAssets.fetched.appendResult(assets) {
            photoCollectionView.insertSections(IndexSet(integer: insertedSection))
            updateVisiblePhotoCollectionCellsEnabled()
        }
    }
}

// MARK: - Photos

