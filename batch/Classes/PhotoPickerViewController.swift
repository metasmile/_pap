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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //photos collection
        photoCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        photoCollectionView.allowsMultipleSelection = true
        
        //peek and pop
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: photoCollectionView)  // self here is UIViewController type, and view is property of UIViewController
        }

        //preview
        batchPreviewView = BatchPreviewView(frame: .zero)
        batchPreviewView.delegate = self
        
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
        
        if numberOfPhotos + numberOfVideos == 0 {
            title = "Batch".localizedString
            
            navigationItem.setLeftBarButton(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)
            
            appDockView.setAccessoryViewToTop(nil)
        }
        else {
            navigationItem.setLeftBarButton(cancelButton, animated: true)
            navigationItem.setRightBarButton(doneButton, animated: true)
            
            appDockView.setAccessoryViewToTop(batchPreviewView)
            
            var itemType = "item"
            if numberOfPhotos > 0 && numberOfVideos == 0 {
                itemType = "photo"
            }
            else if numberOfVideos > 0 && numberOfPhotos == 0 {
                itemType = "video"
            }
            else {
                itemType = "item"
            }
            
            title = "Edit %d \(itemType)(s)".localizedFormattedString(photoCollectionView.indexPathsForSelectedItems?.count ?? 0)
        }
    }
}

extension PhotoPickerViewController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = photoCollectionView?.indexPathForItem(at: location) else { return nil }
        guard let cell = photoCollectionView?.cellForItem(at: indexPath) else { return nil }
        
        let selectedAsset = self.asset(at: indexPath)

        let vc = PhotoPickerDetailViewController()
        vc.asset = selectedAsset
        
        var typeWord = "photo"
        if selectedAsset?.mediaType == .video {
            typeWord = "video"
        }
        
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            vc.actionItems = [UIPreviewAction(title: "Deselect this \(typeWord)".localizedString, style: .default) { action, controller in
                self.photoCollectionView.deselectItem(at: indexPath, animated: false)
                self.collectionView(self.photoCollectionView, didDeselectItemAt: indexPath)
            }]
        }
        else {
            vc.actionItems = [UIPreviewAction(title: "Select this \(typeWord)".localizedString, style: .default) { action, controller in
                self.photoCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.collectionView(self.photoCollectionView, didSelectItemAt: indexPath)
            }]
        }

        previewingContext.sourceRect = cell.frame
        return vc
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

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
        title = "Processing...\(Int(progress * 100))%".localizedString

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
        updateTitleForSelectedItems()

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
    
    private func indexPath(of asset: PHAsset) -> IndexPath? {
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateTitleForSelectedItems()
        
        batchPreviewView.addBatchEditItem(with: self.asset(at: indexPath))
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        batchPreviewView.removeBatchEditItem(with: self.asset(at: indexPath))
        
        updateTitleForSelectedItems()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interitemSpacing = self.collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: indexPath.item)
        let numberOfItemInRow: CGFloat = 4
        
        let gridWidth = (UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).width - interitemSpacing * (numberOfItemInRow - 1)) / numberOfItemInRow
        return CGSize(width: gridWidth, height: gridWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
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
                        })
                    } else {
                        // Reload the collection view if incremental diffs are not available.
                        self.photoCollectionView.reloadData()
                        break
                    }
                }
            }

            
//            var changedIndexPaths = [IndexPath]()
//            var insertedIndexPaths = [IndexPath]()
//            var removedIndexPaths = [IndexPath]()
//
//            struct PhotoLibraryChangedInfo {
//                var indexPath: IndexPath
//                var index: Int
//            }
//
//            for (section, fetchResult) in fetchResults.enumerated() {
//                guard let changeDetails = changeInstance.changeDetails(for: fetchResult.fetchResult) else { continue }
//
//                if let changedInfos = changeDetails.changedIndexes?.enumerated().map({ PhotoLibraryChangedInfo(indexPath: IndexPath(item: $0.element, section: section), index: $0.offset) }) {
//                    for changedInfo in changedInfos {
//                        fetchResult.assets[changedInfo.indexPath.item] = changeDetails.changedObjects[changedInfo.index]
//                        changedIndexPaths.append(changedInfo.indexPath)
//                    }
//                }
//
//                if let changedInfos = changeDetails.insertedIndexes?.enumerated().map({ PhotoLibraryChangedInfo(indexPath: IndexPath(item: $0.element, section: section), index: $0.offset) }) {
//                    for changedInfo in changedInfos {
//                        let insertedAsset = changeDetails.insertedObjects[changedInfo.index]
//                        guard !fetchResult.assets.contains(insertedAsset) else { continue }
//                        fetchResult.assets.insert(insertedAsset, at: changedInfo.indexPath.item)
//                        insertedIndexPaths.append(changedInfo.indexPath)
//                    }
//                }
//                if let indexPaths = changeDetails.removedIndexes?.map({ IndexPath(item: $0, section: section) }) {
//                    removedIndexPaths.append(contentsOf: indexPaths)
//                }
//
//                if changeDetails.hasMoves {
//                    changeDetails.enumerateMoves({ (from, to) in
//                        self.photoCollectionView.moveItem(at: IndexPath(item: from, section: section), to: IndexPath(item: to, section: section))
//                    })
//                }
//            }
//
//            self.photoCollectionView.performBatchUpdates({
////                if removedIndexPaths.count > 0 {
////                    self.photoCollectionView.deleteItems(at: removedIndexPaths)
////                }
//
//                if insertedIndexPaths.count > 0 {
//                    self.photoCollectionView.insertItems(at: insertedIndexPaths)
//                }
//
//                if changedIndexPaths.count > 0 {
//                    self.photoCollectionView.reloadItems(at: changedIndexPaths)
//                }
//            }, completion: { (finished) in
//
//            })
//
//            self.updateTitleForSelectedItems()
        }
    }
}

class PhotoCollectionViewCell: CustomCollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    //TODO: wrap a view as a decorationrenderview later
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var selectionViewWidth: NSLayoutConstraint!
    @IBOutlet weak var selectionViewHeight: NSLayoutConstraint!

    @IBOutlet weak var decorationContainerView: UIView!
    @IBOutlet weak var durationLabelForVideo: UILabel!
    @IBOutlet weak var iconForLivePhotos: UIImageView!

    var selectionCheckView: CheckMark!

    private var selectionViewSize: CGSize = .zero {
        didSet {
            selectionViewWidth.constant = selectionViewSize.width
            selectionViewHeight.constant = selectionViewSize.height
        }
    }

    private static var _durationLabelFormat: DateComponentsFormatter?
    static var durationLabelFormat: DateComponentsFormatter {
        get {
            if _durationLabelFormat == nil {
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .positional
                formatter.allowedUnits = [.minute, .second]
                formatter.zeroFormattingBehavior = [.pad]
                formatter.collapsesLargestUnit = true
                _durationLabelFormat = formatter
            }
            return _durationLabelFormat!
        }
        set(value) { _durationLabelFormat = value }
    }
    
    var indexPath: IndexPath?
    var imageRequestId: PHImageRequestID?
    var imageContentMode = PHImageContentMode.aspectFit

    override func initialize() {
        super.initialize()

        selectionCheckView = CheckMark(frame: CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))
        selectionCheckView.backgroundColor = UIColor.clear

        selectionView.addSubview(selectionCheckView)
        selectionView.backgroundColor = UIColor(white: 1, alpha: 0.25)

        iconForLivePhotos.image = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isSelected = false
        
        imageView.image = nil
        indexPath = nil
        
        if let imageRequestId = imageRequestId {
            PhotoManager.cachingImageManager.cancelImageRequest(imageRequestId)
        }
        imageRequestId = nil
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
    }

    func setAsset(_ asset: PHAsset, at indexPath: IndexPath) {
        self.indexPath = indexPath
        prepareForDisplay(with: asset)

        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .fast

        let targetSizeScale = UIScreen.main.scale
        let targetSize = CGSize(width: imageView.bounds.size.width*targetSizeScale, height: imageView.bounds.size.height*targetSizeScale)

        imageRequestId = PhotoManager.cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions) { [weak self] (image, info) in
            DispatchQueue.main.async { [weak self] in
                guard self?.indexPath == indexPath else { return }
                self?.imageView.image = image
            }
            self?.imageRequestId = nil
        }
    }
    
    override var isSelected: Bool {
        didSet {
            selectionCheckView.checked = isSelected
            selectionView.isHidden = !isSelected
        }
    }
    
    // MARK: - Prepare rendering
    
    private func prepareForDisplay(with asset: PHAsset) {
        updateImageViewContentMode()
        
        let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        selectionViewSize = (imageContentMode == .aspectFit ? AVMakeRect(aspectRatio: imageSize, insideRect: imageView.bounds) : imageView.bounds).size

        let checkmarkSize = selectionCheckView.bounds.size
        let checkmarkmargin:CGFloat = 2.0
        selectionCheckView.frame = CGRect(origin: CGPoint(x: selectionViewSize.height-checkmarkSize.width-checkmarkmargin, y: selectionViewSize.width-checkmarkSize.height-checkmarkmargin), size: checkmarkSize)

        //duration label
        durationLabelForVideo.isHidden = asset.mediaType != .video
        if !durationLabelForVideo.isHidden{
            durationLabelForVideo.text = PhotoCollectionViewCell.durationLabelFormat.string(from: asset.duration)
        }

        //live photo icon
        iconForLivePhotos.isHidden = !asset.mediaSubtypes.contains(.photoLive)

        decorationContainerView.isHidden = durationLabelForVideo.isHidden && iconForLivePhotos.isHidden
    }
    
    private func updateImageViewContentMode() {
        switch imageContentMode {
        case .aspectFill:
            imageView.contentMode = .scaleAspectFill
        default:
            imageView.contentMode = .scaleAspectFit
        }
    }
}
