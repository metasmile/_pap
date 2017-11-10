//
//  PhotoPickerViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 7. 11..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Photos
import Hero

class FetchResultItem: NSObject {
    var fetchResult: PHFetchResult<PHAsset> = PHFetchResult()
    var assets: [PHAsset] = []
    
    convenience init(_ fetchResult: PHFetchResult<PHAsset>) {
        self.init()
        
        self.fetchResult = fetchResult
        self.assets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))
    }
}

class PhotoPickerViewController: UIViewController {
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    @IBOutlet weak var editToolBar: FloatingToolbar!
    @IBOutlet weak var editToolBarBottomLayout: NSLayoutConstraint!
    
    var collections: PHFetchResult<PHAssetCollection>?
    var fetchResults: [FetchResultItem]?
    
    var orderedSelectedIndexPaths = NSMutableOrderedSet()
    
    var editButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        photoCollectionView.register(PhotoCollectionTitleView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoCollectionTitleView")
        photoCollectionView.allowsMultipleSelection = true
        
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
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        editButton = UIBarButtonItem(title: "", style: .done, target: self, action: #selector(self.editButtonDidTap))
        
        editToolBar.toolbarItems = [
            UIBarButtonItem(image: UIImage(named: "Cancel".localizedString), style: .plain, target: self, action: #selector(self.cancelAllSelection)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            editButton
        ]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutToolbar()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func layoutToolbar() {
        if photoCollectionView.indexPathsForSelectedItems?.count == 0 {
            editToolBarBottomLayout.constant = -(editToolBar.bounds.height + safeAreaInsets.bottom)
            photoCollectionView.contentInset.bottom = 0
        }
        else {
            editToolBarBottomLayout.constant = 10
            photoCollectionView.contentInset.bottom = editToolBar.bounds.height + 10
        }
    }
    
    func updateToolBarItems(_ animated: Bool = true) {
        layoutToolbar()
        editToolBar.animateUsingSpringIfLayoutConstraintsChanged()
        
        editButton.title = "Edit %d photo(s)".localizedFormattedString(photoCollectionView.indexPathsForSelectedItems?.count ?? 0)
    }
}

// MARK: - Constraints

extension UIView {
    func constraint(withIdentifier identifier: String) -> NSLayoutConstraint? {
        return constraints.first(where: { $0.identifier == identifier })
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
        
        self.photoCollectionView.reloadData()
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
        DispatchQueue.global().async {
            self.collections = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: collectionSubType, options: nil)
            
            self.fetchResults = [FetchResultItem]()
            self.collections?.enumerateObjects({ (collection, idx, stop) in
                let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
                self.fetchResults?.append(FetchResultItem(fetchResult))
            })
            
            DispatchQueue.main.async {
                self.photoCollectionView.reloadData()
            }
        }
    }
    
    // MARK: - Data
    
    private func asset(at indexPath: IndexPath) -> PHAsset? {
        return fetchResults?[indexPath.section].assets[indexPath.item]
    }
    
    func cancelAllSelection() {
        guard let indexPaths = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in indexPaths {
            photoCollectionView.deselectItem(at: indexPath, animated: true)
        }
        orderedSelectedIndexPaths.removeAllObjects()
        updateToolBarItems()
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResults?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults?[section].assets.count ?? 0
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
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PhotoCollectionTitleView", for: indexPath) as! PhotoCollectionTitleView
            view.title = "Select photos to batch edit".localizedString
            return view
        }
        else {
            return UICollectionReusableView()
        }
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateToolBarItems()
        
        orderedSelectedIndexPaths.add(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateToolBarItems()
        
        orderedSelectedIndexPaths.remove(indexPath)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 48)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interitemSpacing = self.collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: indexPath.item)
        let numberOfItemInRow: CGFloat = 4
        
        let gridWidth = (UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).width - interitemSpacing * (numberOfItemInRow - 1)) / numberOfItemInRow
        return CGSize(width: gridWidth, height: gridWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    // MARK: - Navigation
    
    func editButtonDidTap(sender: Any) {
        guard photoCollectionView.indexPathsForSelectedItems?.isEmpty == false, let selectedIndexPaths = orderedSelectedIndexPaths.array as? [IndexPath] else { return }
        
        let batchEditViewController = storyboard?.instantiateViewController(withIdentifier: "BatchEditViewController") as! BatchEditViewController
        batchEditViewController.photos = selectedIndexPaths.flatMap({ asset(at: $0) })
        batchEditViewController.delegate = self
        
        for indexPath in selectedIndexPaths {
            guard let photo = asset(at: indexPath), let cell = photoCollectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else { continue }
            batchEditViewController.placeholderImages[photo] = cell.imageView.image
        }
        
        let navigationController = UINavigationController(rootViewController: batchEditViewController)
        navigationController.isHeroEnabled = true
        navigationController.heroModalAnimationType = .selectBy(presenting:.zoom, dismissing:.zoomOut)
        navigationController.heroNavigationAnimationType = .none
        navigationController.modalPresentationStyle = .overCurrentContext
        
        present(navigationController, animated: true, completion: nil)
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

extension PhotoPickerViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResults = self.fetchResults else { return }
        
        DispatchQueue.main.async {
            var indexPaths = [IndexPath]()
            
            for (section, fetchResult) in fetchResults.enumerated() {
                guard let changeDetails = changeInstance.changeDetails(for: fetchResult.fetchResult) else { continue }
                for object in changeDetails.changedObjects {
                    guard let item = fetchResult.assets.index(of: object) else { continue }
                    fetchResult.assets[item] = object
                    indexPaths.append(IndexPath(item: item, section: section))
                }
            }
            guard indexPaths.count > 0 else { return }
            self.photoCollectionView.reloadItems(at: indexPaths)
            self.updateToolBarItems()
        }
    }
}

class PhotoCollectionTitleView: CustomCollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBInspectable var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
}

class PhotoCollectionViewCell: CustomCollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var selectionViewWidth: NSLayoutConstraint!
    @IBOutlet weak var selectionViewHeight: NSLayoutConstraint!
    private var selectionViewSize: CGSize = .zero {
        didSet {
            selectionViewWidth.constant = selectionViewSize.width
            selectionViewHeight.constant = selectionViewSize.height
        }
    }
    
    var selectionCheckView: CheckMark!
    
    var indexPath: IndexPath?
    var imageRequestId: PHImageRequestID?
    var imageContentMode = PHImageContentMode.aspectFit

    override func initialize() {
        super.initialize()

        selectionCheckView = CheckMark(frame: CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))
        selectionCheckView.backgroundColor = UIColor.clear

        selectionView.addSubview(selectionCheckView)
        selectionView.backgroundColor = UIColor(white: 1, alpha: 0.25)

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

extension UIViewController {
    var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        }
        else {
            return UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
        }
    }
}
