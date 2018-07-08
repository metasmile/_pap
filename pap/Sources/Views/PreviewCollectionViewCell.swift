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
        
        if layoutAttributes.size != previousAttributes?.size || self.asset != assetItem?.asset {
            setNeedsUpdatePreview()
        }
        
        self.editItem = assetItem
        self.asset = self.editItem?.asset
        
        updatePreviewIfNeeded()
        
        previousAttributes = layoutAttributes
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        asset = nil
        editItem = nil
        previousAttributes = nil
        assetView.isProcessing = false
        assetView.layer.transform = CATransform3DIdentity
        
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
        
        if let editItem = self.editItem {
            setEditItem(editItem)
        }
        
        needsToUpdatePreview = false
    }
    
    func setFilteredImage(_ filtered: UIImage?, original: UIImage? = nil, with item: PHAssetItem<ImageEditStateValue>) {
        let asset = item.asset
        
        setEditItem(item)
        
        if let original = original {
            assetView.originalImage = original
        }
        else {
            assetView.setThumbnailAsset(asset, cancelDrawingIfNeeded: { [weak self] in
                return self?.asset != asset
            }, completion: { [weak self] image in
                guard self?.asset == asset else { return }
                self?.assetView.originalImage = image
            })
        }
        assetView.filteredImage = filtered
        setImageEditItem(item.editState, animated: false)
        assetView.isProcessing(false, animated: true)
    }
    
    func setOriginalImage(_ original: UIImage? = nil, with item: PHAssetItem<ImageEditStateValue>) {
        let asset = item.asset
        
        setEditItem(item)
        
        assetView.filteredImage = nil
        
        if let original = original {
            assetView.originalImage = original
            assetView.image = original
            setImageEditItem(item.editState, animated: false)
        }
        else {
            assetView.setThumbnailAsset(asset, cancelDrawingIfNeeded: { [weak self] in
                return self?.asset != asset
                }, completion: { [weak self] image in
                    guard self?.asset == asset else { return }
                    self?.assetView.originalImage = image
                    if self?.assetView.filteredImage == nil {
                        self?.assetView.image = image
                        self?.setImageEditItem(item.editState, animated: false)
                    }
            })
        }
    }
    
    private func setEditItem(_ item: PHAssetItem<ImageEditStateValue>) {
        let asset = item.asset
        
        self.editItem = item
        self.asset = asset
        
        let boundingSize = asset.pixelWidth > asset.pixelHeight ? bounds.size.applying(item.editState.transform).magnitude : bounds.size
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: boundingSize)
        
        assetViewWidth.constant = photoSize.width
        assetViewHeight.constant = photoSize.height
        
        layoutIfNeeded()
    }
    
    func setEditItemForPreview(_ item: PHAssetItem<ImageEditStateValue>) {
        let asset = item.asset
        
        setEditItem(item)
        
        assetView.setThumbnailAsset(asset, cancelDrawingIfNeeded: { [weak self] in
            return self?.asset != asset
        }, completion: { [weak self] image in
            guard self?.asset == asset else { return }
            
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
