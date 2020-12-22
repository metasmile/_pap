//
// Created by BLACKGENE on 22.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

public typealias PHAssetRequestOption = (targetSize:CGSize, contentMode:PHImageContentMode, options:PHImageRequestOptions?)

public extension PHCachingImageManager{
    @discardableResult
    func requestImage(for asset: PHAsset, option: PHAssetRequestOption, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return requestImage(for: asset, targetSize: option.targetSize, contentMode: option.contentMode, options: option.options, resultHandler: resultHandler)
    }

    func startCachingImages(for assets: [PHAsset], option: PHAssetRequestOption) {
        startCachingImages(for: assets, targetSize: option.targetSize, contentMode: option.contentMode, options: option.options)
    }

    func stopCachingImages(for assets: [PHAsset], option: PHAssetRequestOption) {
        stopCachingImages(for: assets, targetSize: option.targetSize, contentMode: option.contentMode, options: option.options)
    }
}

public extension PHImageManager {
    func touchOriginalVersion(for asset: PHAsset, completion: (() -> Void)?) {
        switch asset.mediaType {
        case .image:
            switch asset.imageType {
            case .livePhoto:
                let livePhotoRequestOptions = PHLivePhotoRequestOptions()
                livePhotoRequestOptions.isNetworkAccessAllowed = true
                livePhotoRequestOptions.version = .original
                
                requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: livePhotoRequestOptions) { (livePhoto, info) in
                    completion?()
                }
            default:
                let imageRequestOptions = PHImageRequestOptions()
                imageRequestOptions.isNetworkAccessAllowed = true
                imageRequestOptions.isSynchronous = false
                imageRequestOptions.version = .original

                requestImageDataAndOrientation(for: asset, options: imageRequestOptions) { (data, uti, imageOrientation, info) in
                    completion?()
                }
            }
        case .video:
            let videoRequestOptions = PHVideoRequestOptions()
            videoRequestOptions.isNetworkAccessAllowed = true
            videoRequestOptions.version = .original
            
            requestAVAsset(forVideo: asset, options: videoRequestOptions) { (video, audioMix, info) in
                completion?()
            }
        default: completion?()
        }
    }
}
