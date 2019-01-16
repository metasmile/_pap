//
//  App.PreviewProcessable.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 31..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos

public protocol PreviewProcessableApp: App {
    //INFO: prevent memory leak for creating CIImage(uiImage:)
    var previewOriginalImageCache: NSCache<NSString, CIImage>? { get set }
    func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void))
    
    //TODO: usage levels?
    func showsVisibleEffectWhileProcessing() -> Bool
    
    //Compare with original
    var previewOriginalBadgeTitle: String { get }
    func previewOriginalImageCompare(with appAsset: AppAsset, targetSize: CGSize) -> UIImage?
}

extension PreviewProcessableApp {
    public var previewOriginalImageCache: NSCache<NSString, CIImage>? { get { return nil } set {} }
    public func showsVisibleEffectWhileProcessing() -> Bool {
        return false
    }
    
    public func cachedOriginalImage(with asset: PHAsset, targetSize: CGSize) -> CIImage? {
        let cacheKey = asset.localIdentifierWithoutSplitter + "\(targetSize)" as NSString
        
        if let image = previewOriginalImageCache?.object(forKey: cacheKey) {
            return image
        }
        else if let image = asset.requestThumbnailImage(targetSize: targetSize)?.asCIImage {
            previewOriginalImageCache?.setObject(image, forKey: cacheKey)
            return image
        }
        else {
            return nil
        }
    }
    
    public var previewOriginalBadgeTitle: String { return "Original".localized }
    public func previewOriginalImageCompare(with appAsset: AppAsset, targetSize: CGSize) -> UIImage? { return nil }
}
