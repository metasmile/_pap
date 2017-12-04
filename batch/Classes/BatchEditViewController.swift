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
import Firebase

protocol BatchEditViewControllerDelegate {
    func batchEditViewControllerDidFinishEditing(_ editor: BatchEditViewController)
    func batchEditViewControllerDidCancelEditing(_ editor: BatchEditViewController)
}

class EditToolbarViewController: UIViewController {
    var cancelButton: UIBarButtonItem?
    var doneButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton = UIBarButtonItem(image: UIImage(named: "Cancel"), style: .plain, target: self, action: #selector(self.cancelButtonDidTap))
        doneButton = UIBarButtonItem(image: UIImage(named: "Batch Done Bar Button"), style: .done, target: self, action: #selector(self.doneButtonDidTap))
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController?.navigationBar.barStyle == UIBarStyle.black {
            cancelButton?.tintColor = .white
            doneButton?.tintColor = .white
        }
        else {
            cancelButton?.tintColor = .black
            doneButton?.tintColor = .black
        }
    }
    
    var appDockItems: [AppDockItem] {
        return [
            AppDockItem(title: "Flip Vertical", appIcon: UIImage(named: "Flip Vertical"), run: { self.verticalFlipButtonDidTap() }),
            AppDockItem(title: "Flip Horizontal", appIcon: UIImage(named: "Flip Horizontal"), run: { self.horizontalFlipButtonDidTap() }),
            AppDockItem(title: "Rotate Left", appIcon: UIImage(named: "Rotate Left"), run: { self.rotationLeftButtonDidTap() }),
            AppDockItem(title: "Rotate Right", appIcon: UIImage(named: "Rotate Right"), run: { self.rotationRightButtonDidTap() })
        ]
    }
    
    @objc func cancelButtonDidTap(sender: Any) {
        
    }
    
    func horizontalFlipButtonDidTap() {
        
    }
    
    func verticalFlipButtonDidTap() {
        
    }
    
    func rotationLeftButtonDidTap() {
        
    }
    
    func rotationRightButtonDidTap() {
        
    }
    
    @objc func doneButtonDidTap(sender: Any) {
        
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
    var batchRequest: BatchEditSequenceRequest?
    
    @IBOutlet weak var previewCollectionView: UICollectionView!
    @IBOutlet weak var appDockView: STAppDockView!
    @IBOutlet weak var appDockViewBottomLayout: NSLayoutConstraint!
    @IBOutlet weak var dimmedView: UIView!
    
    @IBOutlet weak var batchProgressView: BatchProgressView!
    @IBOutlet weak var batchProgressViewBottomLayout: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Batch Edit".localizedString
        
        appDockView.items = appDockItems
        
        batchProgressView.titleLabel.textColor = view.tintColor
        batchProgressView.cancelButton.addTarget(self, action: #selector(self.cancelBatchButtonDidTap), for: .touchUpInside)
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playAssetIfExistsInCenterOfView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopAllPlayAssets()
    }
    
    // MARK: - Editing
    
    @objc func cancelBatchButtonDidTap(sender: Any) {
        batchRequest?.cancel()
        
        closeBatchProgressView()
    }
    
    fileprivate func closeBatchProgressView() {
        batchProgressView.title = nil
        batchProgressView.setProgress(0, animated: false)
        
        batchProgressViewBottomLayout.constant = -(self.batchProgressView.bounds.height + self.safeAreaInsets.bottom)
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.batchProgressView.superview?.layoutIfNeeded()
        }) { (finished) in
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
            self.appDockViewBottomLayout.constant = 10
            self.appDockView.animateUsingSpringIfLayoutConstraintsChanged()
        }
        
        UIView.transition(with: self.dimmedView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.dimmedView.isHidden = true
        }, completion: nil)
    }
    
    fileprivate func showBatchProgressView() {
        batchProgressView.title = "Start Batch Editing...".localizedString
        batchProgressView.setProgress(0, animated: false)
        
        UIView.transition(with: dimmedView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.dimmedView.isHidden = false
        }, completion: nil)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        appDockViewBottomLayout.constant = -(appDockView.bounds.height + safeAreaInsets.bottom)
        appDockView.animateUsingSpringIfLayoutConstraintsChanged()
        
        batchProgressViewBottomLayout.constant = 10
        UIView.animate(withDuration: 0.3, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.batchProgressView.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
    var hasChanges: Bool {
        return batchEditItems.map({ $0.editItem.hasChanges }).contains(true)
    }
    
    func updateBatchEdit(animated: Bool = true, completion: (() -> Void)? = nil) {
        updatePreviews(animated: animated, completion: completion)
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
    
    private func updatePreviews(animated: Bool = true, completion: (() -> Void)? = nil) {
        let numberOfItems = previewCollectionView.numberOfItems(inSection: 0)
        guard numberOfItems > 0 else { completion?(); return }
        
        let visibleRect = CGRect(origin: previewCollectionView.contentOffset, size: previewCollectionView.bounds.size)
        let visibleIndexPath = previewCollectionView.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) ?? previewCollectionView.indexPathsForVisibleItems.last
        
        previewCollectionView.collectionViewLayout.invalidateLayout()
        previewCollectionView.performBatchUpdates({
            
        }) { (finished) in
            guard let indexPath = visibleIndexPath, animated == true else { completion?(); return }
            self.previewCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: false)
            completion?()
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
        alert.addAction(UIAlertAction(title: "Discard Changes".localizedString, style: .destructive, handler: { (action) in
            self.delegate?.batchEditViewControllerDidCancelEditing(self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localizedString, style: .cancel, handler: nil))
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
    
    override func horizontalFlipButtonDidTap() {
        addTransformItem(HorizontalFlipTransformItem())
    }
    
    override func verticalFlipButtonDidTap() {
        addTransformItem(VerticalFlipTransformItem())
    }
    
    override func rotationLeftButtonDidTap() {
        addTransformItem(RotationTransformItem(degrees: -90))
    }
    
    override func rotationRightButtonDidTap() {
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
        showBatchProgressView()
        
        previewCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
        
        batchRequest = BatchEditSequenceRequest()
        batchRequest?.perform(batchEditItems.map({ BatchEditRequest($0) }), { (progress, idx) in
            DispatchQueue.main.async { [weak self] in
                self?.batchProgressView.title = "Processing...".localizedString
                self?.batchProgressView.setProgress(progress, animated: true)
                
                guard let item = idx, let numberOfItems = self?.batchEditItems.count, item + 1 < numberOfItems else { return }
                self?.previewCollectionView.scrollToItem(at: IndexPath(item: item + 1, section: 0), at: .centeredHorizontally, animated: true)
            }
        }) { (results) in
            DispatchQueue.main.async {
                self.batchProgressView.title = "Saving Photos...".localizedString
            }
            
            PHPhotoLibrary.shared().performChanges({
                for result in results {
                    PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
                }
            }, completionHandler: { (success, info) in
                DispatchQueue.main.async { [unowned self] in
                    self.closeBatchProgressView()
                    
                    if success {
                        Analytics.logEvent("log.export.save", parameters: ["number_of_items": self.batchEditItems.count])
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
            cell.assetView.image = image
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
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell,
            cell.assetView.isLivePhotoPlaying == false
        else { return }
        
        cell.assetView.layer.transform = CATransform3DIdentity
        cell.assetView.transform = batchEditItems[indexPath.item].editItem.transform
        
        cell.assetView.heroModifiers = [.fade]
        
        let placeholderImage = cell.assetView.image
        let preferredTransform = batchEditItems[indexPath.item].editItem.transform;
        
        let photoEditViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoEditViewController") as! PhotoEditViewController
        photoEditViewController.placeholderImage = placeholderImage
        photoEditViewController.asset = cell.asset
        photoEditViewController.preferredTransform = preferredTransform
        photoEditViewController.indexPathInBatch = indexPath
        photoEditViewController.delegate = self
        
        let transitionID = "PhotoEditViewTransition"
        let snapshotImageView = UIImageView(image: placeholderImage?.applyTransform(preferredTransform))
        snapshotImageView.contentMode = .scaleAspectFit
        snapshotImageView.frame = cell.assetView.convert(cell.assetView.bounds, to: view)
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

extension BatchEditViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        playAssetIfExistsInCenterOfView()
    }
    
    fileprivate func playAssetIfExistsInCenterOfView() {
        for cell in previewCollectionView.visibleCells {
            guard let cell = cell as? PreviewCollectionViewCell else { continue }
            let cellBoundsInView = cell.assetView.convert(cell.assetView.bounds, to: view)
            if cellBoundsInView.contains(CGPoint(x: view.frame.midX, y: view.frame.midY)) {
                cell.assetView.playWithLooping()
            }
            else {
                cell.assetView.pause()
            }
        }
    }
    
    fileprivate func stopAllPlayAssets() {
        for cell in previewCollectionView.visibleCells {
            guard let cell = cell as? PreviewCollectionViewCell else { continue }
            cell.assetView.pause()
        }
    }
}

extension BatchEditViewController: PhotoEditViewControllerDelegate {
    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: EditItem?, at indexPath: IndexPath?) {
        guard let editItem = editItem, let indexPath = indexPath else {
            photoEditor.dismiss(animated: true, completion: {
                photoEditor.placeholderView?.removeFromSuperview()
            })
            return
        }
        
        batchEditItems[indexPath.item].editItem.transformItems.append(contentsOf: editItem.transformItems)
        
        updateBatchEdit(animated: false) {
            if let cell = self.previewCollectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell, let snapshot = photoEditor.placeholderView {
                let cellBoundsInView = cell.assetView.convert(cell.assetView.bounds, to: self.view)
                let diff = cellBoundsInView.minX - snapshot.frame.minX
                self.previewCollectionView.contentOffset.x += diff
            }
            
            photoEditor.dismiss(animated: true, completion: {
                photoEditor.placeholderView?.removeFromSuperview()
            })
        }
    }
}

class PreviewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var assetView: STAssetView!
    
    var indexPath: IndexPath?
    var asset: PHAsset?
    var imageRequestId: PHImageRequestID?
    var imageContentMode = PHImageContentMode.aspectFit
    
    @IBOutlet weak var assetViewWidth: NSLayoutConstraint!
    @IBOutlet weak var assetViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var imageInfoViewTop: NSLayoutConstraint!
    @IBOutlet weak var fileLabel: UILabel!
    @IBOutlet weak var resolutionLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        assetView.heroID = nil
        assetView.asset = nil
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
        
        assetViewWidth.constant = photoSize.width
        assetViewHeight.constant = photoSize.height
        
        DispatchQueue.main.async { [weak self] in
            guard self?.indexPath == indexPath else { return }
            
            let resources = PHAssetResource.assetResources(for: asset)
            if let firstResource = resources.first {
                self?.fileLabel.text = firstResource.originalFilename
            }
            
            self?.setImageEditItem(item.editItem)
        }
        
        assetView.setAsset(asset, cancelDrawingIfNeeded: { [weak self] in
            return self?.indexPath != indexPath
        })
    }
    
    func setImageEditItem(_ editItem: EditItem, animated: Bool = false) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.assetView.layer.transform = editItem.transform3d
            }) { (finished) in
            }
        }
        else {
            assetView.layer.transform = editItem.transform3d
        }
        
        imageInfoViewTop.constant = (bounds.height + CGSize(width: assetViewWidth.constant, height: assetViewHeight.constant).applying(editItem.transform).magnitude.height) / 2 + 10
        
        if let asset = self.asset {
            let assetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            let transformedAssetSize = assetSize.applying(editItem.transform).magnitude
            resolutionLabel.text = "\(Int(transformedAssetSize.width)) x \(Int(transformedAssetSize.height))"
        }
    }
}
