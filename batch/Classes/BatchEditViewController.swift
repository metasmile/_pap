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

class BatchEditViewController: AppDockViewController {
    var delegate: BatchEditViewControllerDelegate?
    
    var placeholderImages = [PHAsset: UIImage?]()
    
    var targetAssetItems = [PHAssetItem<TransformItem>]()
    var initialIndexPath: IndexPath?
    
    @IBOutlet weak var previewCollectionView: UICollectionView!
    @IBOutlet weak var dimmedView: UIView!
    
    @IBOutlet weak var batchProgressView: BatchProgressView!
    @IBOutlet weak var batchProgressViewBottomLayout: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Batch Edit".localizedString
        
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
        AppTaskManager.shared(2).cancel()
//        batchRequest?.cancel()
        
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
            
            self.showAppDock()
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
        
        hideAppDock()
        
        batchProgressViewBottomLayout.constant = 10
        UIView.animate(withDuration: 0.3, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: {
            self.batchProgressView.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
    var hasChanges: Bool {
        return targetAssetItems.map({ $0.editItem.hasChanges }).contains(true)
    }
    
    func updateBatchEdit(animated: Bool = true, completion: (() -> Void)? = nil) {
        updatePreviews(animated: animated, completion: completion)
        updateToolBarButtonStatus()
    }
    
    private func addTransformItem(_ transformItem: TransformItem) {
        for assetEditItem in targetAssetItems {
            assetEditItem.editItem.append(transformItem)
        }
        
        updateBatchEdit()
    }
    
    private func resetTransformItems() {
        for item in targetAssetItems {
            item.editItem.reset()
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
            cell.setImageEditItem(self.targetAssetItems[indexPath.item].editItem, animated: animated)
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


//TODO: TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP
        targetAssetItems.forEach { item in
            AppTaskManager.shared(2).append(request: AppTaskRequest(TransformApp.self, item) { res, cancel in
                print(item)
            })
        }

        let reaction = AppTaskReaction()
        reaction.when { result, progress, respondables, respondables1 in

            assert(result.result is PHAssetResultItem)
            guard let _ = result.result as? PHAssetResultItem else{
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.batchProgressView.title = "Processing...".localizedString
                self?.batchProgressView.setProgress(Float(progress), animated: true)
//                self?.previewCollectionView.scrollToItem(at: _resultIndexPath, at: .centeredHorizontally, animated: true)
            }

        }
        reaction.when { finishedResultsForEachApps, respondables in

            DispatchQueue.main.async {
                self.batchProgressView.title = "Saving Photos...".localizedString
            }

            let results = respondables.flatMap { $0.result as? PHAssetResultItem
            }

            PHPhotoLibrary.shared().performChanges({
                for result in results {
                    PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
                }
            }, completionHandler: { (success, info) in

                DispatchQueue.main.async { [unowned self] in
                    self.closeBatchProgressView()

                    if success {
                        Analytics.logEvent("log.export.save", parameters: ["number_of_items": self.targetAssetItems.count])
                        self.delegate?.batchEditViewControllerDidFinishEditing(self)
                    }
                }
            })

        }
        AppTaskManager.shared(2).perform(reaction)
//TODO: TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP


//        batchRequest = BatchEditSequenceRequest()
//        batchRequest?.perform(EditItems.map({ BatchEditRequest($0) }), { (progress, idx) in
//            DispatchQueue.main.async { [weak self] in
//                self?.batchProgressView.title = "Processing...".localizedString
//                self?.batchProgressView.setProgress(progress, animated: true)
//
//                guard let item = idx, let numberOfItems = self?.EditItems.count, item + 1 < numberOfItems else { return }
//                self?.previewCollectionView.scrollToItem(at: IndexPath(item: item + 1, section: 0), at: .centeredHorizontally, animated: true)
//            }
//        }) { (results) in
//            DispatchQueue.main.async {
//                self.batchProgressView.title = "Saving Photos...".localizedString
//            }
//
//            PHPhotoLibrary.shared().performChanges({
//                for result in results {
//                    PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
//                }
//            }, completionHandler: { (success, info) in
//
//                DispatchQueue.main.async { [unowned self] in
//                    self.closeBatchProgressView()
//
//                    if success {
//                        Analytics.logEvent("log.export.save", parameters: ["number_of_items": self.EditItems.count])
//                        self.delegate?.batchEditViewControllerDidFinishEditing(self)
//                    }
//                }
//            })
//        }

    }
}

extension BatchEditViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func setupPreviewCollectionView() {
        previewCollectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: "PreviewCollectionViewCell")
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return targetAssetItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCollectionViewCell", for: indexPath) as! PreviewCollectionViewCell
        let photo = targetAssetItems[indexPath.item].asset

        if let image = placeholderImages[photo] {
            cell.assetView.image = image
        }
        cell.setEditItem(targetAssetItems[indexPath.item], at: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let indexPath = initialIndexPath {
            previewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            initialIndexPath = nil
        }
        
        if let cell = cell as? PreviewCollectionViewCell {
            cell.setImageEditItem(self.targetAssetItems[indexPath.item].editItem)
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? PreviewCollectionViewCell,
            cell.assetView.isLivePhotoPlaying == false
        else { return }
        
        cell.assetView.layer.transform = CATransform3DIdentity
        cell.assetView.transform = targetAssetItems[indexPath.item].editItem.transform
        
        cell.assetView.heroModifiers = [.fade]
        
        let placeholderImage = cell.assetView.image
        let preferredTransform = targetAssetItems[indexPath.item].editItem.transform;
        
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
            PhotoManager.cachingImageManager.startCachingImages(for: indexPaths.flatMap({ self.targetAssetItems[$0.item].asset }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
            PhotoManager.cachingImageManager.stopCachingImages(for: indexPaths.flatMap({ self.targetAssetItems[$0.item].asset }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let asset = targetAssetItems[indexPath.item].asset

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
        let cellSize = photoSize.applying(targetAssetItems[indexPath.item].editItem.transform).magnitude
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
                cell.assetView.playVideoWithLooping()
            }
            else {
                cell.assetView.pauseVideo()
            }
        }
    }
    
    fileprivate func stopAllPlayAssets() {
        for cell in previewCollectionView.visibleCells {
            guard let cell = cell as? PreviewCollectionViewCell else { continue }
            cell.assetView.pauseVideo()
        }
    }
}

extension BatchEditViewController: TransformEditViewControllerDelegate {
    func photoEditViewController(_ photoEditor: PhotoEditViewController, didFinishEditing editItem: EditableItem<TransformItem>?, at indexPath: IndexPath?) {
        guard let editItem = editItem, let indexPath = indexPath else {
            photoEditor.dismiss(animated: true, completion: {
                photoEditor.placeholderView?.removeFromSuperview()
            })
            return
        }
        
        targetAssetItems[indexPath.item].editItem.merge(with:editItem)
        
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
