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

extension PhotoPickerViewController {
    var kPhotoPickerNumberOfItemsInRow: CGFloat { return 4 }
}

class PhotoPickerViewController: AppDockViewController {
    @IBOutlet weak var photoCollectionView: UICollectionView!
    var initialPhotoCollectionIndexPath: IndexPath?
    
    var batchPreviewView: PreviewView!
    var progressBar: UIProgressView!

    var dragSelectionGesture: DragSelectionGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //preview
        batchPreviewView = PreviewView(frame: .zero)
        batchPreviewView.delegate = self

        //photos collection
        photoCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        photoCollectionView.register(PhotoPickerFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "PhotoPickerFooterView")
        photoCollectionView.allowsMultipleSelection = true
        
        //peek and pop
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: photoCollectionView)  // self here is UIViewController type, and view is property of UIViewController
            registerForPreviewing(with: self, sourceView: batchPreviewView)
        }

        //watch assets changed
        let resultWatchInfo = PHAssets.fetched.watch(\.results) {
            DispatchQueue.main.async{
                if let numberOfSection = PHAssets.fetched.results?.count, numberOfSection > 0, let numberOfItemsInSection = PHAssets.fetched.results?[numberOfSection - 1].count, numberOfItemsInSection > 0 {
                    self.initialPhotoCollectionIndexPath = IndexPath(item: numberOfItemsInSection - 1, section: numberOfSection - 1)
                }

                //for test
//                PHAssets.fetched.results?.first?.enumerateObjects { asset, i, pointer in
//                    let ads = asset.resources.filter({ r -> Bool in
//                        r.type == .adjustmentData
//                    })
//                    if ads.count > 0{
//                        print("---------------",asset)
//                        for r in asset.resources{
//                            print(r.originalFilename, r.uniformTypeIdentifier)
//                        }
//                    }
//                 }

                self.photoCollectionView.reloadData()
            }
        }

        //photos access authorization
        PHPhotoLibraryManager.default.watch(\.changes) {
            guard let changeInstance = PHPhotoLibraryManager.default.changes else { return }
            PHAssets.fetched.unwatch(\.results, forIds:[resultWatchInfo.id])

            DispatchQueue.main.async {
                self.photoLibraryDidChange(changeInstance)
            }
        }

        PHPhotoLibraryManager.default.authorizeIfNeeded { authorized in
            guard authorized else { return }

            PHAssets.fetched.unload()
            PHAssets.fetched.load(with: .smartAlbum, subtype: .smartAlbumUserLibrary)
         }

        //navigation controller accessories
        title = Bundle.main.displayName

        navigationItem.setLeftBarButton(nil, animated: true)
        navigationItem.setRightBarButton(nil, animated: true)

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AppCenter.default.watch(\.currentIdentifier, options:[.new, .old, .initial]) { (appCenter, dict) in
            if let old = dict.oldValue, old != dict.newValue! {

                AppAssets.selected.reloadAll()
                self.showCurrentSelectedAppDisplayName()

                self.redisplayVisibleCellsWhenChangeApp()
            }

            AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"picker\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform, !AppCenter.default.isAppRunning{
                    AppAssets.selected.appendValue(value)

                    self.batchPreviewView.updatePreviews()
                }
            }
            
            AppCenter.default.currentInstanceAs(PhotosFilterApp.self)?.config?.watch(\.filter, id:"picker\(PhotosFilterApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.isAppRunning{
                    AppAssets.selected.appendValue(value)
                    
                    self.batchPreviewView.updatePreviews()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["picker\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(PhotosFilterApp.self)?.config?.unwatch(\.filter, forIds:["picker\(PhotosFilterApp.info.identifier)"])
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

    func redisplayVisibleCellsWhenChangeApp(){
        for indexPath in self.photoCollectionView.indexPathsForSelectedItems ?? [IndexPath](){
            if !self.collectionView(self.photoCollectionView, shouldSelectItemAt: indexPath) {
                self.deselectCollectionViewItem(at: indexPath, animated: false)
            }
        }

        updateVisiblePhotoCollectionCellsEnabled()
    }

    func showCurrentSelectedAppDisplayName(){
        let previousTitle = self.title == Bundle.main.displayName ? self.title : Bundle.main.displayName

        self.titleFade = AppCenter.default.current?.info.displayName

        Timer.scheduledTimer(identifier: "batch_selectedAppTitle", withTimeInterval: 2, repeats: false) { timer in
            if let _ = self.selectedAssetsInCollectionView {
                self.updateSelectedItemsTitle()
            }else{
                self.titleFade = previousTitle
            }
        }
    }
    
    func updateSelectedItemUIs() {
        updateSelectedItemsTitle()
        updateSelectedItemControls()
    }

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
                title = "Edit %d \(pluralizedString)".localizedFormatted(numberOfPhotos.decimalStyleString)
            }
            else if numberOfVideos > 0 && numberOfPhotos == 0 {
                let pluralizedString = "Video" + (numberOfVideos == 1 ? "" : "s")
                title = "Edit %d \(pluralizedString)".localizedFormatted(numberOfVideos.decimalStyleString)
            }
            else {
                let pluralizedString = "Item" + (numberOfItems == 1 ? "" : "s")
                title = "Edit %d \(pluralizedString)".localizedFormatted(numberOfItems.decimalStyleString)
            }
        }
    }
    
    private func updateSelectedItemControls() {
        let selectedAssets = self.selectedAssetsInCollectionView
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfPhotos = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        let numberOfItems = numberOfPhotos + numberOfVideos
        
        if numberOfItems == 0 {
            navigationItem.setLeftBarButton(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)
            
            appDockView.previewView = nil
        }
        else {
            navigationItem.setLeftBarButton(cancelButton, animated: true)
            navigationItem.setRightBarButton(doneButton, animated: true)
            
            appDockView.previewView = batchPreviewView
        }
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
    
    private func updateAllPhotosTitle() {
        if let footer = self.photoCollectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? PhotoPickerFooterView {
            footer.text = self.formattedStringForAllPhotos
        }
    }
    
    func updatePhotoPickerTitles() {
        updateSelectedItemUIs()
        updateAllPhotosTitle()
    }
    
    func updateVisiblePhotoCollectionCellsEnabled() {
        for indexPath in photoCollectionView.indexPathsForVisibleItems{
            let cell = photoCollectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell
            cell?.isEnabled = collectionView(photoCollectionView, shouldSelectItemAt: indexPath)
        }
    }

    private func photoLibraryDidChange(_ changeInstance: PHChange) {
        let selectedAssetIdentifiers = photoCollectionView.indexPathsForSelectedItems?.flatMap({ PHAssets.fetched.asset(at: $0)?.localIdentifier })
        
        //TODO - confirm: https://fabric.io/jessi/ios/apps/com.stells.batch/issues/5ab6b90e8cb3c2fa63db6d25?time=last-seven-days
        guard let fetchResults = PHAssets.fetched.results else { return }

        let fetchResultChanges = fetchResults.enumerated().flatMap { results -> (Int, PHFetchResultChangeDetails<PHAsset>)? in
            let (section, result) = results
            if let details = changeInstance.changeDetails(for: result){
                return (section, details)
            }
            return nil
        }

        /*
            Handle Tasks while batch performing
        */
        let removedAssets = fetchResultChanges.flatMap { (_, changes) in changes.removedObjects}.reduce([],+)
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

        //perform batch update
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
                    continue
                }

                // If there are incremental diffs, animate them in the collection view.
                // For indexes to make sense, updates must be in this order:
                // delete, insert, reload, move
                if let removed = changes.removedIndexes, removed.count > 0 {
                    self.photoCollectionView.deleteItems(at: removed.map { IndexPath(item: $0, section:section) })
                }
                if let inserted = changes.insertedIndexes, inserted.count > 0 {
                    self.photoCollectionView.insertItems(at: inserted.map { IndexPath(item: $0, section:section) })
                }
                if let changed = changes.changedIndexes, changed.count > 0 {
                    self.photoCollectionView.reloadItems(at: changed.map { IndexPath(item: $0, section:section) })
                }
                changes.enumerateMoves { fromIndex, toIndex in
                    self.photoCollectionView.moveItem(at: IndexPath(item: fromIndex, section: section), to: IndexPath(item: toIndex, section: section))
                }
            }
        }, completion: { _ in
            if tasksWereRanAndRemoved {
                AppCenter.default.task.perform(self.batchPreviewView.createTaskReaction())
            }else{
                self.updatePhotoPickerTitles()
            }
            
            self.restoreSelectionByUser(selectedAssetIdentifiers)
            self.batchPreviewView.reloadPreview()
        })
    }
    
    private func restoreSelectionByUser(_ assetLocalIdentifiers: [String]?) {
        guard let localIdentifiers = assetLocalIdentifiers else { return }
        PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil).enumerateObjects { (asset, idx, stop) in
            self.selectCollectionViewItem(by: asset)
        }
    }
}

extension PhotoPickerViewController: TransformEditViewControllerDelegate {
    func showPhotoEditor(with editItem: PHAssetItem<AppValue>?) {
        guard let _editItem = editItem else { return }

        if let photoEditViewController = R.storyboard.appStoryboard.photoEditViewController(){
            photoEditViewController.asset = _editItem.asset
            photoEditViewController.preferredTransform = _editItem.editState.transform
            photoEditViewController.delegate = self

            if let item = AppAssets.selected.index(of:_editItem) {
                photoEditViewController.indexPathInBatch = IndexPath(item: item, section: 0)
            }

            let navigationController = UINavigationController(rootViewController: photoEditViewController)
            navigationController.hero.isEnabled = true
            navigationController.hero.modalAnimationType = .fade
            navigationController.hero.navigationAnimationType = .fade
            present(navigationController,animated: true) {

                AppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .white))
            }
        }
    }

    func editViewController(_ photoEditor: PhotoEditViewController, didFinishWith editItem: StateValueSet<AppValue>?, at indexPath: IndexPath?) {
        if let _editItem = editItem, let _indexPath = indexPath, _editItem.hasChanges {
            AppAssets.selected.at(_indexPath.item).editState.merge(with: _editItem)
        }

        AppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .black))

        photoEditor.dismiss(animated: true, completion: {
            self.batchPreviewView.reloadCollectionViewItems()
        })
    }
}

extension PhotoPickerViewController: PreviewViewDelegate {
    var currentDisplayableApp:PhotoPickerViewControllerDisplayableApp?{
        if AppCenter.default.current is PhotoPickerViewControllerDisplayableApp.Type{
            return AppCenter.default.currentInstanceAs(PhotoPickerViewControllerDisplayableApp.self)
        }
        return nil
    }

    func batchPreviewView(_ view: PreviewView, didSelectItemAt indexPath: IndexPath) {
        let selectedAsset = AppAssets.selected.at(indexPath.item).asset
        guard let indexPathInPhotoPicker = PHAssets.fetched.indexPath(of: selectedAsset) else { return }
        photoCollectionView.scrollToItem(at: indexPathInPhotoPicker, at: .centeredVertically, animated: true)
        
        
//        guard photoCollectionView.indexPathsForSelectedItems?.isEmpty == false, let selectedIndexPaths = orderedSelectedIndexPaths.array as? [IndexPath] else { return }
//
//        let batchEditViewController = storyboard?.instantiateViewController(withIdentifier: "BatchEditViewController") as! BatchEditViewController
//        batchEditViewController.EditItems = batchPreviewView.EditItems
//        batchEditViewController.delegate = self
//        batchEditViewController.initialIndexPath = indexPath
//
//        for indexPath in selectedIndexPaths {
//            guard let photo = asset(at: indexPath), let cell = photoCollectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else { continue }
//            batchEditViewController.placeholderImages[photo] = cell.imageView.image
//        }
//
//        let navigationController = UINavigationController(rootViewController: batchEditViewController)
//        navigationController.isHeroEnabled = true
//        navigationController.heroModalAnimationType = .selectBy(presenting:.zoom, dismissing:.zoomOut)
//        navigationController.heroNavigationAnimationType = .none
//        navigationController.modalPresentationStyle = .overCurrentContext
//
//        present(navigationController, animated: true, completion: nil)
    }
    
    func batchPreviewViewWillBeginEdit(_ view: PreviewView) {
        titleFade = currentDisplayableApp?.titleWillBegin()
                ?? "Start Batch Editing...".localized

        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingIndicator), animated: true)

        progressBar.isHidden = false
        progressBar.progress = 0
        UIView.animate(withDuration: 0.2) {
            self.progressBar.alpha = 1
        }
    }
    
    func batchPreviewView(_ view: PreviewView, didUpdateProgress progress: Float) {
        titleFade = currentDisplayableApp?.titleDidUpdate(progress: progress)
                ?? "Processing...".localized + " \(Int(progress * 100))%"

        progressBar.setProgress(progress, animated: true)
    }

    func batchPreviewViewWillCancelProgress(_ view: PreviewView) {
        titleFade = currentDisplayableApp?.titleWillCancel()
                ?? "Cancelling...".localized

        UIView.animate(withDuration: 0.6) {
            self.progressBar.alpha = 0
        }
    }

    func batchPreviewViewWillFinalize(_ view: PreviewView) {
        titleFade = currentDisplayableApp?.titleWillFinalize()
                ?? "Saving Photos...".localized

        UIView.animate(withDuration: 0.6) {
            self.progressBar.alpha = 0
        }
    }
    
    func batchPreviewViewDidEndEdit(_ view: PreviewView) {
        progressBar.isHidden = true

        updateSelectedItemUIs()
        updateVisiblePhotoCollectionCellsEnabled()
    }
    
    func batchPreviewViewDidCancelEdit(_ view: PreviewView) {
        // waiting for remaining processing
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.updateAllPhotosTitle()
        }

        progressBar.isHidden = true
    }
}

// MARK: - Photos

