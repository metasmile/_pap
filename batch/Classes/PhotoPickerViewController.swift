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

class PhotoPickerViewController: AppDockViewController {
    @IBOutlet weak var photoCollectionView: UICollectionView!
    var initialPhotoCollectionIndexPath: IndexPath?
    
    var batchPreviewView: BatchPreviewView!
    var progressBar: UIProgressView!

    var collections: PHFetchResult<PHAssetCollection>?
    var fetchResults: [PHFetchResult<PHAsset>]?
    
    var dragSelectionGesture: STDragSelectionGestureRecognizer!
    
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
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            
        }
        else {
            
        }
        
        requestPhotoLibraryAuthorizationIfNeeded { [unowned self] (authorized) in
            guard authorized else { return }
            
            PHPhotoLibrary.shared().register(self)
            
            DispatchQueue.main.async { [unowned self] in
                self.reloadPhotos(with: .smartAlbum, subtype: .smartAlbumUserLibrary)
            }
        }

        //navigation controller accessories
        title = "Batch".localizedString

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
        
        dragSelectionGesture = STDragSelectionGestureRecognizer(target: self, action: #selector(self.dragSelectionGestureDidRecognize))
        dragSelectionGesture.delegate = self
        photoCollectionView.addGestureRecognizer(dragSelectionGesture)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        photoCollectionView.contentInset.bottom = appDockView.bounds.height - safeAreaInsets.bottom
        photoCollectionView.scrollIndicatorInsets.bottom = photoCollectionView.contentInset.bottom
    }
    
    override func cancelButtonDidTap(sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        //FIXME: BatchPreviewState
        //FIXME: .ready?
        //FIXME: .selecting?
        //FIXME: .processing?
        if batchPreviewView.isProcessing {
            batchPreviewView.cancelBatchProcessing()
        }
        else {
            if batchPreviewView.hasChanges {
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
    
    override func horizontalFlipButtonDidTap() {
        batchPreviewView.addTransformItem(HorizontalFlipTransformItem())
    }
    
    override func verticalFlipButtonDidTap() {
        batchPreviewView.addTransformItem(VerticalFlipTransformItem())
    }
    
    override func rotationLeftButtonDidTap() {
        batchPreviewView.addTransformItem(RotationTransformItem(degrees: -90))
    }
    
    override func rotationRightButtonDidTap() {
        batchPreviewView.addTransformItem(RotationTransformItem(degrees: 90))
    }
}

extension PhotoPickerViewController {
    func updateTitleForSelectedItems() {
        let selectedAssets = photoCollectionView.indexPathsForSelectedItems?.flatMap({ self.asset(at: $0) })
        let numberOfVideos = selectedAssets?.filter({ $0.mediaType == .video }).count ?? 0
        let numberOfPhotos = selectedAssets?.filter({ $0.mediaType == .image }).count ?? 0
        let numberOfItems = numberOfPhotos + numberOfVideos
        
        if numberOfItems == 0 {
            title = "Batch".localizedString
            
            navigationItem.setLeftBarButton(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)
            
            appDockView.setAccessoryViewToTop(nil)
        }
        else {
            navigationItem.setLeftBarButton(cancelButton, animated: true)
            navigationItem.setRightBarButton(doneButton, animated: true)
            
            appDockView.setAccessoryViewToTop(batchPreviewView)
            
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

extension PhotoPickerViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if previewingContext.sourceView == photoCollectionView {
            guard let indexPath = photoCollectionView.indexPathForItem(at: location) else { return nil }
            guard let selectedAsset = self.asset(at: indexPath) else { return nil }
            guard let cell = photoCollectionView.cellForItem(at: indexPath) else { return nil }
            
            let vc = PhotoPickerDetailViewController()
            vc.asset = selectedAsset
            vc.batchEditItem = batchPreviewView.batchEditItems.first(where: { $0.asset == selectedAsset })
            setActions(with: selectedAsset, at: indexPath, to: vc)

            previewingContext.sourceRect = cell.frame
            return vc
        }
        else if previewingContext.sourceView == batchPreviewView {
            guard let indexPath = batchPreviewView.collectionView.indexPathForItem(at: batchPreviewView.convert(location, to: batchPreviewView.collectionView)) else { return nil }
            guard let cell = batchPreviewView.collectionView.cellForItem(at: indexPath) else { return nil }
            
            let batchEditItem = batchPreviewView.batchEditItems[indexPath.item]
            guard let selectedAsset = batchEditItem.asset else { return nil }
            guard let selectedIndexPath = self.indexPath(of: selectedAsset) else { return nil }
            
            let vc = PhotoPickerDetailViewController()
            vc.asset = selectedAsset
            vc.batchEditItem = batchEditItem
            setActions(with: selectedAsset, at: selectedIndexPath, to: vc)
            
            previewingContext.sourceRect = batchPreviewView.collectionView.convert(cell.frame, to: batchPreviewView)
            return vc
        }
        else {
            return nil
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? PhotoPickerDetailViewController {
            if let batchEditItem = vc.batchEditItem {
                showPhotoEditor(with: batchEditItem)
            }
            else {
                showPhotoEditorAndSelectIfNeeded(with: vc.asset)
            }
        }
    }
    
    private func setActions(with asset: PHAsset, at indexPath: IndexPath, to vc: PhotoPickerDetailViewController) {
        var typeWord = "photo"
        if asset.mediaType == .video {
            typeWord = "video"
        }
        
        let editAction = UIPreviewAction(title: "Edit this \(typeWord)".localizedString, style: .default) { (action, controller) in
            self.showPhotoEditorAndSelectIfNeeded(with: asset)
        }
        
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            vc.actionItems = [
                UIPreviewAction(title: "Deselect this \(typeWord)".localizedString, style: .default) { action, controller in
                    self.photoCollectionView.deselectItem(at: indexPath, animated: false)
                    self.collectionView(self.photoCollectionView, didDeselectItemAt: indexPath)
                },
                editAction
            ]
        }
        else {
            vc.actionItems = [
                UIPreviewAction(title: "Select this \(typeWord)".localizedString, style: .default) { action, controller in
                    self.photoCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    self.collectionView(self.photoCollectionView, didSelectItemAt: indexPath)
                },
                editAction
            ]
        }
    }
}

extension PhotoPickerViewController: PhotoEditViewControllerDelegate {
    fileprivate func showPhotoEditor(with batchEditItem: BatchEditItem?) {
        guard let batchEditItem = batchEditItem else { return }
        let photoEditViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoEditViewController") as! PhotoEditViewController
        photoEditViewController.asset = batchEditItem.asset
        photoEditViewController.preferredTransform = batchEditItem.editItem.transform
        photoEditViewController.delegate = self
        if let item = batchPreviewView.batchEditItems.index(of: batchEditItem) {
            photoEditViewController.indexPathInBatch = IndexPath(item: item, section: 0)
        }
        
        let navigationController = UINavigationController(rootViewController: photoEditViewController)
        navigationController.isHeroEnabled = true
        navigationController.heroModalAnimationType = .fade
        navigationController.heroNavigationAnimationType = .fade
        present(navigationController, animated: true, completion: nil)
    }
    
    fileprivate func showPhotoEditorAndSelectIfNeeded(with asset: PHAsset?) {
        selectItemInPhotoPicker(with: asset)
        showPhotoEditor(with: batchPreviewView.batchEditItems.first(where: { $0.asset == asset }))
    }
    
    fileprivate func selectItemInPhotoPicker(with asset: PHAsset?) {
        guard let indexPath = self.indexPath(of: asset) else { return }
        selectItemIfNotSelected(at: indexPath)
    }
    
    fileprivate func selectItemIfNotSelected(at indexPath: IndexPath) {
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false {
            photoCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            collectionView(photoCollectionView, didSelectItemAt: indexPath)
        }
    }
    
    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: EditItem?, at indexPath: IndexPath?) {
        if let editItem = editItem, let indexPath = indexPath {
            batchPreviewView.batchEditItems[indexPath.item].editItem.merge(editItem)
        }
        
        photoEditor.dismiss(animated: true, completion: {
            self.batchPreviewView.reloadBatchEditItems()
        })
    }
}

extension PhotoPickerViewController: BatchPreviewViewDelegate {
    func batchPreviewView(_ view: BatchPreviewView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedAsset = view.batchEditItems[indexPath.item].asset, let indexPathInPhotoPicker = self.indexPath(of: selectedAsset) else { return }
        photoCollectionView.scrollToItem(at: indexPathInPhotoPicker, at: .centeredVertically, animated: true)
        
        
//        guard photoCollectionView.indexPathsForSelectedItems?.isEmpty == false, let selectedIndexPaths = orderedSelectedIndexPaths.array as? [IndexPath] else { return }
//
//        let batchEditViewController = storyboard?.instantiateViewController(withIdentifier: "BatchEditViewController") as! BatchEditViewController
//        batchEditViewController.batchEditItems = batchPreviewView.batchEditItems
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
        title = "Start Batch Editing...".localizedString

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
        title = "Processing...".localizedString + " \(Int(progress * 100))%"

        progressBar.setProgress(progress, animated: true)
    }
    
    func batchPreviewViewWillBeginExport(_ view: BatchPreviewView) {
        title = "Saving Photos...".localizedString

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

class PhotoManager: NSObject {
    static let cachingImageManager = PHCachingImageManager()
}

extension PhotoPickerViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    fileprivate func requestPhotoLibraryAuthorizationIfNeeded(_ completion: @escaping ((Bool) -> ())) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            DispatchQueue.main.async { completion(true) }
            break
        case .notDetermined:
            DispatchQueue.main.async {
                self.requestPhotoLibraryAuthorization(completion)
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showPhotoLibrarySettingsAlert()
                completion(false)
            }
        }
    }
    
    fileprivate func requestPhotoLibraryAuthorization(_ completion: @escaping ((Bool) -> ())) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async { completion(true) }
            case .notDetermined, .denied, .restricted:
                DispatchQueue.main.async {
                    self.showPhotoLibrarySettingsAlert()
                    completion(false)
                }
            }
        }
    }
    
    fileprivate func showPhotoLibrarySettingsAlert() {
        let alert = UIAlertController(title: "Photos Access Disabled".localizedString, message: "Please open settings and allow access to your photos".localizedString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings".localizedString, style: .default, handler: { (action) in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localizedString, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func reloadPhotos(with collectionType: PHAssetCollectionType = .smartAlbum, subtype collectionSubType: PHAssetCollectionSubtype = .smartAlbumUserLibrary) {
        self.collections = nil
        self.fetchResults = nil
        
        photoCollectionView.reloadData()
        
        let options = PHFetchOptions()
        
        DispatchQueue.global().async {
            self.collections = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: collectionSubType, options: nil)
            
            self.fetchResults = [PHFetchResult<PHAsset>]()
            self.collections?.enumerateObjects({ (collection, idx, stop) in
                let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
                self.fetchResults?.append(fetchResult)
            })
            
            if let numberOfSection = self.fetchResults?.count, numberOfSection > 0, let numberOfItemsInSection = self.fetchResults?[numberOfSection - 1].count, numberOfItemsInSection > 0 {
                self.initialPhotoCollectionIndexPath = IndexPath(item: numberOfItemsInSection - 1, section: numberOfSection - 1)
            }
            
            DispatchQueue.main.async {
                self.photoCollectionView.reloadData()
            }
        }
    }
    
    // MARK: - Data
    
    private func asset(at indexPath: IndexPath) -> PHAsset? {
        return fetchResults?[indexPath.section][indexPath.item]
    }
    
    private func indexPath(of asset: PHAsset?) -> IndexPath? {
        guard let asset = asset else { return nil }
        return fetchResults?.enumerated().flatMap({
            let item = $0.element.index(of: asset)
            guard item != NSNotFound else { return nil }
            return IndexPath(item: item, section: $0.offset)
        }).first
    }
    
    @objc func cancelAllSelection() {
        guard let indexPaths = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in indexPaths {
            photoCollectionView.deselectItem(at: indexPath, animated: true)
        }
        
        batchPreviewView.removeAllBatchEditItems()
        updateTitleForSelectedItems()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResults?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults?[section].count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        if let asset = asset(at: indexPath) {
            cell.imageContentMode = .aspectFill
            cell.setAsset(asset, at: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PhotoPickerFooterView", for: indexPath) as! PhotoPickerFooterView
        view.text = generatePhotoPickerText()
        return view
    }
    
    fileprivate func generatePhotoPickerText() -> String {
        var numberOfImages = 0
        var numberOfVideos = 0
        
        fetchResults?.forEach { fetchResult in
            numberOfImages += fetchResult.countOfAssets(with: PHAssetMediaType.image)
            numberOfVideos += fetchResult.countOfAssets(with: PHAssetMediaType.video)
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        var footerText = ""
        if numberOfImages > 0 {
            if numberOfImages == 1 {
                footerText += "%d Photo".localizedFormattedString(numberOfImages.decimalStyleString)
            }
            else {
                footerText += "%d Photos".localizedFormattedString(numberOfImages.decimalStyleString)
            }
        }
        
        if numberOfVideos > 0 {
            if numberOfImages > 0 {
                footerText += ", "
            }
            
            if numberOfVideos == 1 {
                footerText += "%d Video".localizedFormattedString(numberOfVideos.decimalStyleString)
            }
            else {
                footerText += "%d Videos".localizedFormattedString(numberOfVideos.decimalStyleString)
            }
        }
        
        return footerText
    }
    
    // MARK: - UICollectionViewDataSourcePrefetching
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PhotoManager.cachingImageManager.startCachingImages(for: indexPaths.flatMap({ self.asset(at: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PhotoManager.cachingImageManager.stopCachingImages(for: indexPaths.flatMap({ self.asset(at: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let indexPath = initialPhotoCollectionIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            initialPhotoCollectionIndexPath = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if batchPreviewView.isProcessing {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if batchPreviewView.isProcessing {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateTitleForSelectedItems()
        
        batchPreviewView.addBatchEditItem(with: self.asset(at: indexPath))
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        batchPreviewView.removeBatchEditItem(with: self.asset(at: indexPath))
        
        updateTitleForSelectedItems()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    fileprivate var kPhotoPickerNumberOfItemsInRow: CGFloat { return 4 }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interitemSpacing = self.collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: indexPath.item)
        
        let gridWidth = (UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).width - interitemSpacing * (kPhotoPickerNumberOfItemsInRow - 1)) / kPhotoPickerNumberOfItemsInRow
        return CGSize(width: gridWidth, height: gridWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
}

extension PhotoPickerViewController: BatchEditViewControllerDelegate {
    func batchEditViewControllerDidCancelEditing(_ editor: BatchEditViewController) {
        editor.dismiss(animated: true, completion: nil)
    }
    
    func batchEditViewControllerDidFinishEditing(_ editor: BatchEditViewController) {
        cancelAllSelection()
        editor.dismiss(animated: true, completion: nil)
    }
}

// https://developer.apple.com/documentation/photos/phphotolibrarychangeobserver
extension PhotoPickerViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResults = self.fetchResults else { return }
        
        DispatchQueue.main.async {
            for (section, fetchResult) in fetchResults.enumerated() {
                if let changes = changeInstance.changeDetails(for: fetchResult) {
                    // Keep the new fetch result for future use.
                    self.fetchResults?[section] = changes.fetchResultAfterChanges
                    if changes.hasIncrementalChanges {
                        // If there are incremental diffs, animate them in the collection view.
                        self.photoCollectionView.performBatchUpdates({
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
                        }, completion: { _ in
                            self.updateTitleForSelectedItems()
                            if let footer = self.photoCollectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? PhotoPickerFooterView {
                                footer.text = self.generatePhotoPickerText()
                            }
                        })
                    } else {
                        // Reload the collection view if incremental diffs are not available.
                        self.photoCollectionView.reloadData()
                        self.updateTitleForSelectedItems()
                        if let footer = self.photoCollectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? PhotoPickerFooterView {
                            footer.text = self.generatePhotoPickerText()
                        }
                        break
                    }
                }
            }
        }
    }
}

extension PhotoPickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == dragSelectionGesture {
            let velocity = dragSelectionGesture.velocity(in: dragSelectionGesture.view)
            return velocity.x.magnitude > velocity.y.magnitude
        }
        return true
    }
    
    @objc func dragSelectionGestureDidRecognize(sender: STDragSelectionGestureRecognizer) {
        let touchLocation = sender.location(in: sender.view)
        
        switch sender.state {
        case .began:
            dragSelectionGesture.reset()
            
            guard let indexPath = photoCollectionView.indexPathForItem(at: touchLocation) else { return }
            dragSelectionGesture.selectionMode = photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true ? .deselect : .select
            dragSelectionGesture.beginIndexPath = indexPath
            dragSelectionGesture.beginLocation = touchLocation
            
            dragSelection(with: [indexPath])
            
            dragSelectionGesture.ignoredIndexPaths = photoCollectionView.indexPathsForSelectedItems
            
            photoCollectionView.isScrollEnabled = false
        case .changed:
            drag(at: touchLocation, with: sender.selectionMode)
            panWithDragging(at: touchLocation)
        default:
            photoCollectionView.isScrollEnabled = true
            sender.reset()
        }
        updateTitleForSelectedItems()
    }
    
    private func drag(at location: CGPoint, with selectionMode: STDragSelectionGestureRecognizer.DragSelectionMode) {
        guard
            let beginLocation = dragSelectionGesture.beginLocation,
            let beginIndexPath = dragSelectionGesture.beginIndexPath
        else { return }
        
        var draggingArea = CGRect(x: min(beginLocation.x, location.x), y: min(beginLocation.y, location.y), width: (beginLocation.x - location.x).magnitude, height: (beginLocation.y - location.y).magnitude)
        draggingArea.origin.x = 0
        draggingArea.size.width = photoCollectionView.bounds.width
        
        var groupDirection = STDragSelectionGestureRecognizer.AutoPanningDirection.none
        if let currentIndexPath = photoCollectionView.indexPathForItem(at: location) {
            let beginRow = beginIndexPath.item / Int(kPhotoPickerNumberOfItemsInRow)
            let currentRow = currentIndexPath.item / Int(kPhotoPickerNumberOfItemsInRow)

            let diffRow = currentRow - beginRow
            if diffRow > 0 {
                groupDirection = .down
            }
            else if diffRow < 0 {
                groupDirection = .up
            }
        }
        else {
            let diffLocation = location.y - beginLocation.y
            if diffLocation > 0 {
                groupDirection = .down
            }
            else if diffLocation < 0 {
                groupDirection = .up
            }
        }
        
        var groupedIndexPaths = [IndexPath]()
        photoCollectionView.collectionViewLayout.layoutAttributesForElements(in: draggingArea)?.forEach { layoutAttributes in
            let indexPath = layoutAttributes.indexPath
            
            if let currentIndexPath = photoCollectionView.indexPathForItem(at: location) {
                switch groupDirection {
                case .down:
                    guard indexPath >= beginIndexPath, indexPath <= currentIndexPath else { return }
                case .up:
                    guard indexPath <= beginIndexPath, indexPath >= currentIndexPath else { return }
                default:
                    if currentIndexPath < beginIndexPath { // pan to left
                        guard indexPath <= beginIndexPath, indexPath >= currentIndexPath else { return }
                    }
                    else if currentIndexPath > beginIndexPath { // pan to right
                        guard indexPath >= beginIndexPath, indexPath <= currentIndexPath else { return }
                    }
                    else {
                        guard currentIndexPath == indexPath else { return }
                    }
                }
            }
            else {
                switch groupDirection {
                case .down:
                    guard indexPath >= beginIndexPath else { return }
                case .up:
                    guard indexPath <= beginIndexPath else { return }
                default:
                    return
                }
            }
            groupedIndexPaths.append(indexPath)
        }
        
        var ignoredIndexPaths = [IndexPath]()
        if selectionMode == .select {
            photoCollectionView.indexPathsForSelectedItems?.forEach { indexPath in
                guard
                    dragSelectionGesture.ignoredIndexPaths?.contains(indexPath) == false,
                    !groupedIndexPaths.contains(indexPath)
                else { return }
                
                ignoredIndexPaths.append(indexPath)
            }
            
            dragDeselection(with: ignoredIndexPaths)
            dragSelection(with: groupedIndexPaths)
        }
        else if selectionMode == .deselect {
            dragSelectionGesture.ignoredIndexPaths?.forEach { indexPath in
                guard !groupedIndexPaths.contains(indexPath) else { return }
                ignoredIndexPaths.append(indexPath)
            }
            
            photoCollectionView.indexPathsForSelectedItems?.forEach { indexPath in
                guard !groupedIndexPaths.contains(indexPath), !ignoredIndexPaths.contains(indexPath) else { return }
                ignoredIndexPaths.append(indexPath)
            }
            
            dragDeselection(with: groupedIndexPaths)
            dragSelection(with: ignoredIndexPaths)
        }
    }
    
    private func dragSelection(with indexPaths: [IndexPath]) {
        _ = indexPaths.map({ self.dragSelection(at: $0) })
    }
    
    private func dragDeselection(with indexPaths: [IndexPath]) {
        _ = indexPaths.map({ self.dragDeselection(at: $0) })
    }
    
    private func dragSelection(at indexPath: IndexPath) {
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false {
            photoCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            collectionView(photoCollectionView, didSelectItemAt: indexPath)
        }
    }
    
    private func dragDeselection(at indexPath: IndexPath) {
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            photoCollectionView.deselectItem(at: indexPath, animated: false)
            collectionView(photoCollectionView, didDeselectItemAt: indexPath)
        }
    }
    
    private func panWithDragging(at location: CGPoint) {
        let pointInScreen = photoCollectionView.convert(location, to: view)
        let boundingInsets = UIEdgeInsetsMake(safeAreaInsets.top, 0, photoCollectionView.contentInset.bottom, 0)
        let boundingArea = UIEdgeInsetsInsetRect(photoCollectionView.frame, boundingInsets)
        guard !boundingArea.contains(pointInScreen) else {
            dragSelectionGesture.stopAutoPanning()
            return
        }
        
        var panVelocity: CGFloat = 0
        let scrollDirection: STDragSelectionGestureRecognizer.AutoPanningDirection = (pointInScreen.y <= boundingArea.minY) ? .up : .down
        switch scrollDirection {
        case .up:
            panVelocity = (boundingInsets.top - pointInScreen.y) / boundingInsets.top
            dragSelectionGesture.panAutomatically { [weak self] in
                guard let collectionView = self?.photoCollectionView else { return }
                let autoPanningOffsetY = collectionView.contentOffset.y - STDragSelectionGestureRecognizer.kSTDragSelectionGestureRecognizerAutoPanningIncrement * panVelocity
                let beginOfContentOffsetY = -boundingInsets.top
                if autoPanningOffsetY > beginOfContentOffsetY {
                    collectionView.contentOffset.y = autoPanningOffsetY
                }
                else {
                    collectionView.contentOffset.y = beginOfContentOffsetY
                }
            }
        case .down:
            panVelocity = (pointInScreen.y - boundingArea.maxY) / boundingInsets.bottom
            dragSelectionGesture.panAutomatically { [weak self] in
                guard let collectionView = self?.photoCollectionView else { return }
                let autoPanningOffsetY = collectionView.contentOffset.y + STDragSelectionGestureRecognizer.kSTDragSelectionGestureRecognizerAutoPanningIncrement * panVelocity
                let endOfContentOffsetY = collectionView.contentSize.height - (self?.appDockView.frame.minY ?? 0)
                if autoPanningOffsetY < endOfContentOffsetY {
                    collectionView.contentOffset.y = autoPanningOffsetY
                }
                else {
                    collectionView.contentOffset.y = endOfContentOffsetY
                }
            }
        default:
            break
        }
    }
}

class STDragSelectionGestureRecognizer: UIPanGestureRecognizer {
    static var kSTDragSelectionGestureRecognizerAutoPanningIncrement: CGFloat = 10
    
    enum DragSelectionMode {
        case none
        case select
        case deselect
    }
    
    enum AutoPanningDirection {
        case none
        case up
        case down
    }
    
    var beginIndexPath: IndexPath?
    var ignoredIndexPaths: [IndexPath]?
    var beginLocation: CGPoint?
    var selectionMode = STDragSelectionGestureRecognizer.DragSelectionMode.none
    var autoPanningTimer: CADisplayLink?
    
    @objc func reset() {
        beginIndexPath = nil
        beginLocation = nil
        ignoredIndexPaths = nil
        selectionMode = .none
        stopAutoPanning()
    }
    
    private var panHandler: (() -> Void)?
    func panAutomatically(_ panBlock: (() -> Void)?) {
        if autoPanningTimer == nil {
            autoPanningTimer = CADisplayLink(target: self, selector: #selector(self.autoPanningTimerDidChange))
            autoPanningTimer?.add(to: .main, forMode: .commonModes)
        }
        panHandler = panBlock
    }
    
    func stopAutoPanning() {
        autoPanningTimer?.remove(from: .main, forMode: .commonModes)
        autoPanningTimer = nil
        panHandler = nil
    }
    
    @objc func autoPanningTimerDidChange(sender: CADisplayLink) {
        self.panHandler?()
    }
}

class PhotoPickerFooterView: UICollectionReusableView {
    var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    private func initialize() {
        label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    }
    
    var text: String? {
        didSet {
            label.text = text
        }
    }
}

extension Int {
    var decimalStyleString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
