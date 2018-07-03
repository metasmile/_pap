//
//  PreviewCollectionViewCell.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos

class PreviewCollectionViewCell: CustomCollectionViewCell {
    @IBOutlet weak var assetView: AppUIAssetView!
    
    var indexPath: IndexPath?
    var asset: PHAsset?
    var editItem: PHAssetItem<ImageEditStateValue>?
    var imageRequestId: PHImageRequestID?
    var imageContentMode = PHImageContentMode.aspectFit
    private var needsToUpdatePreview: Bool = false
    
    @IBOutlet weak var assetViewWidth: NSLayoutConstraint!
    @IBOutlet weak var assetViewHeight: NSLayoutConstraint!
    
    private var previousAttributes: UICollectionViewLayoutAttributes?
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        guard let asset = self.asset else { return }
        
        if layoutAttributes.size != previousAttributes?.size || self.editItem != AppAssets.selected.by(asset) {
            setNeedsUpdatePreview()
        }
        
        self.editItem = AppAssets.selected.by(asset)
        
        updatePreviewIfNeeded()
        
        previousAttributes = layoutAttributes
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        assetView.asset = nil
        editItem = nil
        indexPath = nil
        previousAttributes = nil
        assetView.isProcessing = false
        
        if let imageRequestId = imageRequestId {
            PHPhotoLibraryManager.cachingImageManager.cancelImageRequest(imageRequestId)
        }
        imageRequestId = nil
    }
    
    private func setNeedsUpdatePreview() {
        self.needsToUpdatePreview = true
    }
    
    private func updatePreviewIfNeeded() {
        guard self.needsToUpdatePreview else { return }
        
        if let editItem = self.editItem, let indexPath = self.indexPath {
            setEditItemForPreview(editItem, at: indexPath)
        }
        
        needsToUpdatePreview = false
    }
    
    func setEditItemForPreview(_ item: PHAssetItem<ImageEditStateValue>, at indexPath: IndexPath, completion: (() -> Void)?) {
        let asset = item.asset
        
        self.editItem = item
        self.asset = asset
        self.indexPath = indexPath
        
        let boundingSize = asset.pixelWidth > asset.pixelHeight ? bounds.size.applying(item.editState.transform).magnitude : bounds.size
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        
        assetViewWidth.constant = photoSize.width
        assetViewHeight.constant = photoSize.height
        
        layoutIfNeeded()
        assetView.setThumbnailAsset(asset, cancelDrawingIfNeeded: { [weak self] in
            return self?.indexPath != indexPath
        }, completion: { [weak self] image in
            guard self?.indexPath == indexPath else { return }
            completion?()
        })
    }
    
    static private var previewOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    
    func setEditItemForPreview(_ item: PHAssetItem<ImageEditStateValue>, at indexPath: IndexPath) {
        let asset = item.asset
        
        self.editItem = item
        self.asset = asset
        self.indexPath = indexPath
        
        let boundingSize = asset.pixelWidth > asset.pixelHeight ? bounds.size.applying(item.editState.transform).magnitude : bounds.size
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        
        assetViewWidth.constant = photoSize.width
        assetViewHeight.constant = photoSize.height
        
        layoutIfNeeded()
        
        assetView.setThumbnailAsset(asset, cancelDrawingIfNeeded: { [weak self] in
            return self?.indexPath != indexPath
        }, completion: { [weak self] image in
            if let app = AppCenter.default.currentInstanceAs(PreviewCachableApp.self), let cached = app.cachedPreviewImage(item, at: indexPath) {
                self?.assetView.filteredImage = cached
            }
            else {
                self?.setAssetItem(item, at: indexPath)
            }
        })
    }
    
    public func setAssetItem(_ item: PHAssetItem<ImageEditStateValue>, at indexPath: IndexPath, animated: Bool = false) {
        guard self.indexPath == indexPath else { return }
        if let app = AppCenter.default.currentInstanceAs(PreviewableApp.self), app.previewAsynchronously {
            self.assetView.isProcessing = true
            
            PreviewCollectionViewCell.previewOperationQueue.addOperation { [weak self] in
                guard self?.indexPath == indexPath else { return }
                
                app.previewAsync(item, at: indexPath) { [weak self] (image) in
                    DispatchQueue.main.async {
                        self?.assetView.isProcessing(false, animated: true)
                        guard self?.indexPath == indexPath else { return }
                        self?.assetView.filteredImage = image
                    }
                }
            }
        }
        else {
            self.setImageEditItem(item.editState, animated: animated)
        }
    }
    
    private func setImageEditItem<T>(_ editItem: StateValueSet<T>, animated: Bool = false) where T: ImageEditStateValue {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.assetView.layer.transform = editItem.transform3d
            }) { (finished) in
            }
        }
        else {
            assetView.layer.transform = editItem.transform3d
        }
        
        assetView.applyEditState(editItem)
    }
    
    private func setAssetInfo<T>(_ asset: PHAsset, editItem: StateValueSet<T>) where T: ImageEditStateValue {
//        let resources = PHAssetResource.assetResources(for: asset)
//        if let firstResource = resources.first {
//            fileLabel.text = firstResource.originalFilename
//        }
//        
//        let assetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
//        let transformedAssetSize = assetSize.applying(editItem.transform).magnitude
//        resolutionLabel.text = "\(Int(transformedAssetSize.width)) x \(Int(transformedAssetSize.height))"
    }
}
