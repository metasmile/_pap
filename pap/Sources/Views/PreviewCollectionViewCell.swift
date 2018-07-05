//
//  PreviewCollectionViewCell.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 12. 6..
//  Copyright © 2017년 Stells. All rights reserved.
//

import UIKit
import Photos

public struct PreviewProcessingQueue {
    //INFO: controlQueue must be higher than dispatchQueue for its priority
    private static let controlQueue =  DispatchQueue.main
    
    //INFO: Write 'canceled' must be a dispatchqueue that has earlier QoS than .utility
    private static var canceled = false {
        didSet {
            if canceled == true {
                PreviewProcessingQueue.operationQueue.cancelAllOperations()
                PreviewProcessingQueue.cachedPreviewImages.removeAll()
            }
        }
    }
    
    static func cancel() {
        controlQueue.async {
            canceled = true
        }
    }
    
    fileprivate static var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "PreviewableApp.ProcessingOperationQueue"
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    
    private static var cachedPreviewImages = [String: URL]()
    
    private static func cacheIdentifier(with item: AppAsset, targetSize: CGSize) -> String {
        return "\(item.asset.localIdentifierWithoutSplitter)_\(targetSize)_\(item.editState.iterator().reversed().first?.hash ?? 0))"
    }
    
    fileprivate static func cacheImage(_ image: UIImage, targetSize: CGSize, with item: AppAsset) {
        let identifier = cacheIdentifier(with: item, targetSize: targetSize)
        let url = FileURL.temp(identifier, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
        if cachedPreviewImages[identifier] == nil, let data = UIImageJPEGRepresentation(image, 0.7), (try? data.write(to: url)) != nil {
            cachedPreviewImages[identifier] = url
        }
    }
    
    fileprivate static func cachedImage(item: AppAsset, targetSize: CGSize) -> UIImage? {
        let identifier = cacheIdentifier(with: item, targetSize: targetSize)
        guard let url = cachedPreviewImages[identifier] else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

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
        
        var hasCached = false
        if let _ = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self), let cachedImage = PreviewProcessingQueue.cachedImage(item: item, targetSize: self.assetView.bounds.size) {
            hasCached = true
            assetView.filteredImage = cachedImage
        }
        
        assetView.setThumbnailAsset(asset, cancelDrawingIfNeeded: { [weak self] in
            return self?.indexPath != indexPath
        }, completion: { [weak self] image in
            guard self?.indexPath == indexPath, !hasCached else { return }
            
            self?.assetView.image = image
            self?.setAssetItem(item, at: indexPath, animated: true)
        })
    }
    
    public func setAssetItem(_ item: PHAssetItem<ImageEditStateValue>, at indexPath: IndexPath, animated: Bool = false) {
        if let app = AppCenter.default.currentInstanceAs(PreviewProcessableApp.self) {
            self.assetView.isProcessing = true
            
            let targetSize = self.assetView.bounds.size
            
            PreviewProcessingQueue.operationQueue.addOperation { [weak self] in
                guard self?.indexPath == indexPath else { return }
                
                app.previewProcessing(item, targetSize: targetSize) { [weak self] (image) in
                    if let image = image {
                        PreviewProcessingQueue.cacheImage(image, targetSize: targetSize, with: item)
                    }
                    
                    DispatchQueue.main.async {
                        guard self?.indexPath == indexPath else { return }
                        
                        self?.assetView.isProcessing(false, animated: animated)
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
