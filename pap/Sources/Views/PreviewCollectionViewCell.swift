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
        
        let assetItem = AppAssets.selected.at(unsafeIndex: layoutAttributes.indexPath.item)
        
        if layoutAttributes.size != previousAttributes?.size || self.editItem != assetItem || self.indexPath != layoutAttributes.indexPath || self.asset != assetItem?.asset {
            setNeedsUpdatePreview()
        }
        
        self.editItem = assetItem
        self.asset = self.editItem?.asset
        self.indexPath = layoutAttributes.indexPath
        
        updatePreviewIfNeeded()
        
        previousAttributes = layoutAttributes
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        asset = nil
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
            setEditItem(editItem, at: indexPath)
        }
        
        needsToUpdatePreview = false
    }
    
    func setEditItem(_ item: PHAssetItem<ImageEditStateValue>, at indexPath: IndexPath) {
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
            
            self?.assetView.originalImage = image
            self?.setImageEditItem(item.editState, animated: true)
        })
    }
    
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
            guard self?.indexPath == indexPath else { return }
            
            self?.assetView.originalImage = image
            self?.assetView.image = image
            self?.setImageEditItem(item.editState, animated: true)
        })
    }
    
    func setImageEditItem<T>(_ editItem: StateValueSet<T>, animated: Bool = false) where T: ImageEditStateValue {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.assetView.layer.transform = editItem.transform3d
            }) { (finished) in
            }
        }
        else {
            assetView.layer.transform = editItem.transform3d
        }
//        assetView.applyEditState(editItem)
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
