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
    
    var batchPreviewView: BatchPreviewView!
    var progressBar: UIProgressView!

    var collections: PHFetchResult<PHAssetCollection>?
    var fetchResults: [PHFetchResult<PHAsset>]?
    
    var dragSelectionGesture: DragSelectionGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //preview
        batchPreviewView = BatchPreviewView(frame: .zero)
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

        //photos access authorization
        PhotoManager.default.requestPhotoLibraryAuthorizationIfNeeded { [unowned self] (authorized) in
            guard authorized else { return }
            
            PHPhotoLibrary.shared().register(self)
            
            DispatchQueue.main.async { [unowned self] in
                self.reloadPhotos(with: .smartAlbum, subtype: .smartAlbumUserLibrary)
            }
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

        BatchAppCenter.default.watch(\.currentIdentifier, id:"picker", options:[.new,.old,.initial]) { (appCenter, dict) in
            if let old = dict.oldValue, old != dict.newValue! {

                BatchAppAssets.shared.reloadAll()
                self.showCurrentSelectedAppDisplayName()
            }

            BatchAppCenter.default.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"picker\(TransformApp.info.identifier)") { (config, changed) in
                print(config,config.transform)
                if let value = config.transform, !BatchAppCenter.default.isAppRunning{
                    BatchAppAssets.shared.appendValue(value)

                    self.batchPreviewView.updatePreviews()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        BatchAppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["picker\(TransformApp.info.identifier)"])
        BatchAppCenter.default.unwatch(\.currentIdentifier, forIds:["picker"])
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        photoCollectionView.contentInset.bottom = appDockInsets.bottom
        photoCollectionView.scrollIndicatorInsets.bottom = photoCollectionView.contentInset.bottom
    }
    
    override func cancelButtonDidTap(sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if BatchAppCenter.default.isAppRunning {
            batchPreviewView.cancelBatchProcessing()
        }
        else {
            if BatchAppAssets.shared.hasChanges {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Discard Changes".localizedString, style: .destructive, handler: { (action) in
                    self.cancelAllSelection()
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localizedString, style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            else {
                cancelAllSelection()
            }
        }
    }
    
    override func doneButtonDidTap(sender: Any) {
        batchPreviewView.runBatchProcessing()
    }

    func showCurrentSelectedAppDisplayName(){
        let previousTitle = self.title == Bundle.main.displayName ? self.title : Bundle.main.displayName

        self.titleFade = BatchAppCenter.default.current?.info.displayName

        Timer.scheduledTimer(identifier: "batch_selectedAppTitle", withTimeInterval: 2, repeats: false) { timer in
            if let _ = self.selectedAssets{
                self.updateTitleForSelectedItems()
            }else{
                self.titleFade = previousTitle
            }
        }
    }

    func updateTitleForSelectedItems() {
        let selectedAssets = self.selectedAssets
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfPhotos = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        let numberOfItems = numberOfPhotos + numberOfVideos

        if numberOfItems == 0 {
            title = Bundle.main.displayName

            navigationItem.setLeftBarButton(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)

            appDockView.removeAccessoryViewsOnTop(batchPreviewView)
        }
        else {
            navigationItem.setLeftBarButton(cancelButton, animated: true)
            navigationItem.setRightBarButton(doneButton, animated: true)

            appDockView.addAccessoryViewToTop(batchPreviewView)

            if numberOfPhotos > 0 && numberOfVideos == 0 {
                let pluralizedString = "Photo" + (numberOfPhotos == 1 ? "" : "s")
                title = "Edit %d \(pluralizedString)".localizedFormattedString(numberOfPhotos.decimalStyleString)
            }
            else if numberOfVideos > 0 && numberOfPhotos == 0 {
                let pluralizedString = "Video" + (numberOfVideos == 1 ? "" : "s")
                title = "Edit %d \(pluralizedString)".localizedFormattedString(numberOfVideos.decimalStyleString)
            }
            else {
                let pluralizedString = "Item" + (numberOfItems == 1 ? "" : "s")
                title = "Edit %d \(pluralizedString)".localizedFormattedString(numberOfItems.decimalStyleString)
            }
        }
    }
}

extension PhotoPickerViewController: TransformEditViewControllerDelegate {
    func showPhotoEditor(with editItem: PHAssetItem<BatchAppValue>?) {
        guard let _editItem = editItem else { return }

        if let photoEditViewController = R.storyboard.appStoryboard.photoEditViewController(){
            photoEditViewController.asset = _editItem.asset
            photoEditViewController.preferredTransform = _editItem.editState.transform
            photoEditViewController.delegate = self

            if let item = BatchAppAssets.shared.index(of:_editItem) {
                photoEditViewController.indexPathInBatch = IndexPath(item: item, section: 0)
            }

            let navigationController = UINavigationController(rootViewController: photoEditViewController)
            navigationController.hero.isEnabled = true
            navigationController.hero.modalAnimationType = .fade
            navigationController.hero.navigationAnimationType = .fade
            present(navigationController,animated: true) {

                BatchAppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .white))
            }
        }
    }

    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: StateValueSet<BatchAppValue>?, at indexPath: IndexPath?) {

        if let _editItem = editItem, let _indexPath = indexPath, _editItem.hasChanges {
            BatchAppAssets.shared.at(_indexPath.item).editState.merge(with: _editItem)
        }

        BatchAppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues( AppConfigUIAttrribute(tintColor: .black))

        photoEditor.dismiss(animated: true, completion: {
            self.batchPreviewView.reloadCollectionViewItems()
        })
    }

    func showPhotoEditorAndSelectIfNeeded(with asset: PHAsset?) {
        selectItemInPhotoPicker(with: asset)

        showPhotoEditor(with: BatchAppAssets.shared.by(asset))
    }
    
    private func selectItemInPhotoPicker(with asset: PHAsset?) {
        guard let indexPath = self.indexPath(of: asset) else { return }
        selectItemIfNotSelected(at: indexPath)
    }
    
    private func selectItemIfNotSelected(at indexPath: IndexPath) {
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false {
            photoCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            collectionView(photoCollectionView, didSelectItemAt: indexPath)
        }
    }

    var selectedAssets:[PHAsset]?{
        return photoCollectionView.indexPathsForSelectedItems?.flatMap({ self.asset(at: $0) })
    }
}

extension PhotoPickerViewController: BatchPreviewViewDelegate {
    func batchPreviewView(_ view: BatchPreviewView, didSelectItemAt indexPath: IndexPath) {
        let selectedAsset = BatchAppAssets.shared.at(indexPath.item).asset
        guard let indexPathInPhotoPicker = self.indexPath(of: selectedAsset) else { return }
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
    
    func batchPreviewViewWillBeginEdit(_ view: BatchPreviewView) {
        titleFade = "Start Batch Editing...".localizedString

        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingIndicator), animated: true)

        progressBar.isHidden = false
        progressBar.progress = 0
        UIView.animate(withDuration: 0.2) {
            self.progressBar.alpha = 1
        }
    }
    
    func batchPreviewView(_ view: BatchPreviewView, didUpdateProgress progress: Float) {
        titleFade = "Processing...".localizedString + " \(Int(progress * 100))%"

        progressBar.setProgress(progress, animated: true)
    }

    func batchPreviewViewDidCancelProgress(_ view: BatchPreviewView) {
        titleFade = "Cancelling...".localizedString

        UIView.animate(withDuration: 0.6) {
            self.progressBar.alpha = 0
        }
    }

    func batchPreviewViewWillBeginExport(_ view: BatchPreviewView) {
        titleFade = "Saving Photos...".localizedString

        UIView.animate(withDuration: 0.6) {
            self.progressBar.alpha = 0
        }
    }
    
    func batchPreviewViewDidEndEdit(_ view: BatchPreviewView) {
        cancelAllSelection()

        progressBar.isHidden = true
    }
    
    func batchPreviewViewDidCancelEdit(_ view: BatchPreviewView) {
        // waiting for remaining processing
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.updateTitleForSelectedItems()
        }

        progressBar.isHidden = true
    }
}

// MARK: - Photos

