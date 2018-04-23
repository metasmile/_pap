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
    @IBOutlet weak var assetView: AssetView!
    
    var indexPath: IndexPath?
    var asset: PHAsset?
    var imageRequestId: PHImageRequestID?
    var imageContentMode = PHImageContentMode.aspectFit
    
    @IBOutlet weak var assetViewWidth: NSLayoutConstraint!
    @IBOutlet weak var assetViewHeight: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        assetView.asset = nil
        indexPath = nil
        
        if let imageRequestId = imageRequestId {
            PHPhotoLibraryManager.cachingImageManager.cancelImageRequest(imageRequestId)
        }
        imageRequestId = nil
    }
    
    func setEditItem(_ item: PHAssetItem<ImageEditStateValue>, at indexPath: IndexPath) {
        let asset = item.asset

        self.asset = asset
        self.indexPath = indexPath
        
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight).aspectFit(in: CGSize(width: kEditItemPreviewWidth, height: kEditItemPreviewWidth))
        
        assetViewWidth.constant = photoSize.width
        assetViewHeight.constant = photoSize.height
        
        DispatchQueue.main.async { [weak self] in
            guard self?.indexPath == indexPath else { return }
            self?.setAssetInfo(asset, editItem: item.editState)
        }
        
        layoutIfNeeded()
        assetView.setAsset(asset, cancelDrawingIfNeeded: { [weak self] in
            return self?.indexPath != indexPath
        }, completion: { [weak self] result in
            self?.setImageEditItem(item.editState)
        })
    }
    
    func setEditItemForPreview(_ item: PHAssetItem<ImageEditStateValue>, at indexPath: IndexPath) {
        let asset = item.asset
        
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
            self?.setImageEditItem(item.editState)
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
