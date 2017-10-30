//
//  BatchEditViewController.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 8. 24..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import Hero

protocol BatchEditViewControllerDelegate {
    func batchEditViewControllerDidFinishEditing(_ editor: BatchEditViewController)
    func batchEditViewControllerDidCancelEditing(_ editor: BatchEditViewController)
}

class EditToolbarViewController: UIViewController {
    var doneButton: UIBarButtonItem?
    
    var editToolbarItems: [UIBarButtonItem] {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonDidTap))
        self.doneButton = doneButton
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpace.width = 10
        
        return [
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelButtonDidTap)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(image: UIImage(named: "Flip Vertical"), style: .plain, target: self, action: #selector(self.verticalFlipButtonDidTap)),
            fixedSpace,
            UIBarButtonItem(image: UIImage(named: "Flip Horizontal"), style: .plain, target: self, action: #selector(self.horizontalFlipButtonDidTap)),
            fixedSpace,
            UIBarButtonItem(image: UIImage(named: "Rotate Left"), style: .plain, target: self, action: #selector(self.rotationLeftButtonDidTap)),
            fixedSpace,
            UIBarButtonItem(image: UIImage(named: "Rotate Right"), style: .plain, target: self, action: #selector(self.rotationRightButtonDidTap)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            doneButton
        ]
    }
    
    func cancelButtonDidTap(sender: Any) {
        
    }
    
    func horizontalFlipButtonDidTap(sender: Any) {
        
    }
    
    func verticalFlipButtonDidTap(sender: Any) {
        
    }
    
    func rotationLeftButtonDidTap(sender: Any) {
        
    }
    
    func rotationRightButtonDidTap(sender: Any) {
        
    }
    
    func doneButtonDidTap(sender: Any) {
        
    }
}

class BatchEditViewController: EditToolbarViewController {
    var delegate: BatchEditViewControllerDelegate?
    
    var photos: [PHAsset]? {
        didSet {
            guard let photos = photos else { return }
            for photo in photos {
                let batchEditItem = BatchEditItem()
                batchEditItem.asset = photo
                batchEditItems.append(batchEditItem)
            }
        }
    }
    var placeholderImages = [PHAsset: UIImage?]()
    
    var batchEditItems = [BatchEditItem]()
    var editTaskQueue = TaskQueue()
    
    @IBOutlet weak var previewCollectionView: UICollectionView!
    @IBOutlet weak var editToolbar: FloatingToolbar!
    @IBOutlet weak var editToolbarBottomLayout: NSLayoutConstraint!
    @IBOutlet weak var dimmedView: UIView!
    
    @IBOutlet weak var batchProgressView: BatchProgressView!
    @IBOutlet weak var batchProgressViewBottomLayout: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Batch Edit"
        
        editToolbar.toolbarItems = editToolbarItems
        
        updateToolBarButtonStatus()
        
        setupPreviewCollectionView()
    }
    
    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        batchProgressViewBottomLayout.constant = -(batchProgressView.bounds.height + safeAreaInsets.bottom)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: - Editing
    
    var hasChanges: Bool {
        return batchEditItems.map({ $0.editItem.hasChanges }).contains(true)
    }
    
    func updateBatchEdit(animated: Bool = true) {
        updatePreviews(animated: animated)
        updateToolBarButtonStatus()
    }
    
    private func undoBatchEditing() {
        for batchEditItem in batchEditItems {
            guard !batchEditItem.editItem.transformItems.isEmpty else { continue }
            batchEditItem.editItem.transformItems.removeLast()
        }
        
        updateBatchEdit()
    }
    
    private func addTransformItem(_ transformItem: TransformItem) {
        for batchEditItem in batchEditItems {
            batchEditItem.editItem.addTransformItem(transformItem)
        }
        
        updateBatchEdit()
    }
    
    private func resetTransformItems() {
        for batchEditItem in batchEditItems {
            batchEditItem.editItem.resetTransforms()
        }
        
        updateBatchEdit()
    }
    
    private func updatePreviews(animated: Bool = true) {
        let numberOfItems = previewCollectionView.numberOfItems(inSection: 0)
        guard numberOfItems > 0 else { return }
        
        let visibleRect = CGRect(origin: previewCollectionView.contentOffset, size: previewCollectionView.bounds.size)
        let visibleIndexPath = previewCollectionView.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) ?? previewCollectionView.indexPathsForVisibleItems.last
        
        previewCollectionView.collectionViewLayout.invalidateLayout()
        previewCollectionView.performBatchUpdates({
            
        }) { (finished) in
            guard let indexPath = visibleIndexPath, animated == true else { return }
            self.previewCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
        }
        
        let visibleIndexPaths = previewCollectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard let cell = self.previewCollectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { continue }
            cell.setImageEditItem(self.batchEditItems[indexPath.item].editItem, animated: animated)
        }
    }
    
    // MARK: - Navigation Bar Actions
    
    override func cancelButtonDidTap(sender: Any) {
        guard hasChanges else {
            delegate?.batchEditViewControllerDidCancelEditing(self)
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Discard Changes", style: .destructive, handler: { (action) in
            self.delegate?.batchEditViewControllerDidCancelEditing(self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Tool Bar Actions
    
    func updateToolBarButtonStatus() {
        doneButton?.isEnabled = hasChanges
    }
    
    func resetButtonDidTap(sender: Any) {
        resetTransformItems()
    }
    
    func undoButtonDidTap(sender: Any) {
        undoBatchEditing()
    }
    
    override func horizontalFlipButtonDidTap(sender: Any) {
        addTransformItem(HorizontalFlipTransformItem())
    }
    
    override func verticalFlipButtonDidTap(sender: Any) {
        addTransformItem(VerticalFlipTransformItem())
    }
    
    override func rotationLeftButtonDidTap(sender: Any) {
        addTransformItem(RotationTransformItem(degrees: -90))
    }
    
    override func rotationRightButtonDidTap(sender: Any) {
        addTransformItem(RotationTransformItem(degrees: 90))
    }
    
    override func doneButtonDidTap(sender: Any) {
        self.previewCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
        self.previewCollectionView.performBatchUpdates(nil, completion: { [unowned self] (finished) in
            self.runBatchProcessing()
        })
    }
}

extension BatchEditViewController {
    func runBatchProcessing() {
        batchProgressView.title = "Start Batch Editing..."
        batchProgressView.setProgress(0, animated: false)
        
        UIView.transition(with: dimmedView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.dimmedView.isHidden = false
        }, completion: nil)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        editToolbarBottomLayout.constant = -(editToolbar.bounds.height + safeAreaInsets.bottom)
        editToolbar.animateUsingSpringIfLayoutConstraintsChanged()
        
        batchProgressViewBottomLayout.constant = 10
        UIView.animate(withDuration: 0.3, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.batchProgressView.superview?.layoutIfNeeded()
        }) { (finished) in
            
        }
        
        var assetChangeInfos = [(PHAsset, PHContentEditingOutput)]()
        
        let mainTaskGroup = DispatchGroup()
        for (i, batchEditItem) in batchEditItems.enumerated() {
            mainTaskGroup.enter()
            
            editTaskQueue.addTask(DispatchWorkItem { [weak self] in
                batchEditItem.runEditing { [weak self] (asset, contentEditingOutput) in
                    if let asset = asset, let contentEditingOutput = contentEditingOutput {
                        assetChangeInfos.append((asset, contentEditingOutput))
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.batchProgressView.title = "Processing..."
                        self?.batchProgressView.setProgress(Float(i + 1) / Float(self?.batchEditItems.count ?? 1), animated: true)
                        
                        self?.previewCollectionView.scrollToItem(at: IndexPath(item: i, section: 0), at: .centeredHorizontally, animated: true)
                        self?.previewCollectionView.performBatchUpdates(nil, completion: { [weak self] (finished) in
                            mainTaskGroup.leave()
                            
                            self?.editTaskQueue.performNext()
                        })
                    }
                }
            })
        }
        
        editTaskQueue.performNext()
        
        mainTaskGroup.notify(queue: DispatchQueue.main) { [unowned self] in
            self.batchProgressView.title = "Saving Photos..."
            
            PHPhotoLibrary.shared().performChanges({
                for assetChangeInfo in assetChangeInfos {
                    PHAssetChangeRequest(for: assetChangeInfo.0).contentEditingOutput = assetChangeInfo.1
                }
            }, completionHandler: { (success, info) in
                DispatchQueue.main.async { [unowned self] in
                    self.batchProgressView.title = nil
                    self.batchProgressView.setProgress(0, animated: false)
                    
                    self.batchProgressViewBottomLayout.constant = -(self.batchProgressView.bounds.height + self.safeAreaInsets.bottom)
                    UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
                        self.batchProgressView.superview?.layoutIfNeeded()
                    }) { (finished) in
                        self.navigationController?.setNavigationBarHidden(false, animated: true)
                        
                        self.editToolbarBottomLayout.constant = 10
                        self.editToolbar.animateUsingSpringIfLayoutConstraintsChanged()
                    }
                    
                    UIView.transition(with: self.dimmedView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                        self.dimmedView.isHidden = true
                    }, completion: nil)
                    
                    if success {
                        self.delegate?.batchEditViewControllerDidFinishEditing(self)
                    }
                }
            })
        }
    }
}

extension BatchEditViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func setupPreviewCollectionView() {
        
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return batchEditItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCollectionViewCell", for: indexPath) as! PreviewCollectionViewCell
        if let photo = batchEditItems[indexPath.item].asset, let image = placeholderImages[photo] {
            cell.imageView.image = image
        }
        cell.setBatchEditItem(batchEditItems[indexPath.item], at: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PreviewCollectionViewCell {
            cell.setImageEditItem(self.batchEditItems[indexPath.item].editItem)
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell else { return }
        
        cell.imageView.layer.transform = CATransform3DIdentity
        cell.imageView.transform = batchEditItems[indexPath.item].editItem.transform
        
        let photoEditViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoEditViewController") as! PhotoEditViewController
        photoEditViewController.image = cell.imageView.image?.applyTransform(batchEditItems[indexPath.item].editItem.transform)
        photoEditViewController.indexPathInBatch = indexPath
        photoEditViewController.delegate = self
        
        let transitionID = "PhotoEditViewTransition"
        let snapshotImageView = UIImageView(image: photoEditViewController.image)
        snapshotImageView.contentMode = .scaleAspectFit
        snapshotImageView.frame = cell.imageView.convert(cell.imageView.bounds, to: view)
        snapshotImageView.heroID = transitionID
        snapshotImageView.heroModifiers = [.durationMatchLongest]
        view.addSubview(snapshotImageView)
        
        photoEditViewController.placeholderView = snapshotImageView
        photoEditViewController.transitionID = transitionID
        
        let navigationController = UINavigationController(rootViewController: photoEditViewController)
        navigationController.isHeroEnabled = true
        navigationController.heroModalAnimationType = .fade
        navigationController.heroNavigationAnimationType = .fade
        present(navigationController, animated: true, completion: nil)
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: - UICollectionViewDataSourcePrefetching
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
            PhotoManager.cachingImageManager.startCachingImages(for: indexPaths.flatMap({ self.batchEditItems[$0.item].asset }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
            PhotoManager.cachingImageManager.stopCachingImages(for: indexPaths.flatMap({ self.batchEditItems[$0.item].asset }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let asset = batchEditItems[indexPath.item].asset else { return .zero }
        let contentInset: UIEdgeInsets
        if #available(iOS 11.0, *) {
            contentInset = collectionView.adjustedContentInset
        }
        else {
            contentInset = collectionView.contentInset
        }
        
        let contentSize = UIEdgeInsetsInsetRect(collectionView.bounds, contentInset).size
        let boundingSize = CGSize(width: kEditItemPreviewWidth, height: kEditItemPreviewWidth)
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        let cellSize = photoSize.applying(batchEditItems[indexPath.item].editItem.transform).magnitude
        return CGSize(width: cellSize.width, height: contentSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let numberOfItems = collectionView.numberOfItems(inSection: section)
        guard numberOfItems > 0 else { return .zero }
        
        let firstItemSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: section))
        let lastItemSize = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: numberOfItems - 1, section: section))
        
        return UIEdgeInsets(top: 0, left: (collectionView.bounds.width - firstItemSize.width) / 2, bottom: 0, right: (collectionView.bounds.width - lastItemSize.width) / 2)
    }
}

extension BatchEditViewController: PhotoEditViewControllerDelegate {
    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: EditItem?, at indexPath: IndexPath?) {
        guard let editItem = editItem, let indexPath = indexPath else { return }
        
        batchEditItems[indexPath.item].editItem.transformItems.append(contentsOf: editItem.transformItems)
        
        updateBatchEdit(animated: false)
    }
}

class PreviewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    var indexPath: IndexPath?
    var asset: PHAsset?
    var imageRequestId: PHImageRequestID?
    var imageContentMode = PHImageContentMode.aspectFit
    
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var imageInfoViewTop: NSLayoutConstraint!
    @IBOutlet weak var fileLabel: UILabel!
    @IBOutlet weak var resolutionLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.heroID = nil
        imageView.image = nil
        indexPath = nil
        
        if let imageRequestId = imageRequestId {
            PhotoManager.cachingImageManager.cancelImageRequest(imageRequestId)
        }
        imageRequestId = nil
    }
    
    func setBatchEditItem(_ item: BatchEditItem, at indexPath: IndexPath) {
        guard let asset = item.asset else { return }
        
        self.asset = asset
        self.indexPath = indexPath
        
        let boundingSize = CGSize(width: kEditItemPreviewWidth, height: kEditItemPreviewWidth)
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        
        imageViewWidth.constant = photoSize.width
        imageViewHeight.constant = photoSize.height
        
        DispatchQueue.main.async { [weak self] in
            guard self?.indexPath == indexPath else { return }
            
            let resources = PHAssetResource.assetResources(for: asset)
            if let firstResource = resources.first {
                self?.fileLabel.text = firstResource.originalFilename
            }
            
            self?.setImageEditItem(item.editItem)
        }
        
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFill(in: boundingSize)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        DispatchQueue.global().async { [weak self] in
            guard self?.indexPath == indexPath else { return }
            
            self?.imageRequestId = PhotoManager.cachingImageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { [weak self] (image, info) in
                guard self?.indexPath == indexPath else { return }
                
                DispatchQueue.main.async { [weak self] in
                    guard self?.indexPath == indexPath else { return }
                    self?.imageView.image = image
                }
            }
        }
    }
    
    func setImageEditItem(_ editItem: EditItem, animated: Bool = false) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.imageView.layer.transform = editItem.transform3d
            }) { (finished) in
            }
        }
        else {
            imageView.layer.transform = editItem.transform3d
        }
        
        imageInfoViewTop.constant = (bounds.height + CGSize(width: imageViewWidth.constant, height: imageViewHeight.constant).applying(editItem.transform).magnitude.height) / 2 + 10
        
        if let asset = self.asset {
            let assetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            let transformedAssetSize = assetSize.applying(editItem.transform).magnitude
            resolutionLabel.text = "\(Int(transformedAssetSize.width)) x \(Int(transformedAssetSize.height))"
        }
    }
}
