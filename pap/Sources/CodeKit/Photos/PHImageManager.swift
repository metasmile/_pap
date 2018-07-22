//
// Created by BLACKGENE on 22.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

public struct PHAssetRequestedImage {
    let image: UIImage
    let request: PHImageManagerRequest
}

public typealias PHImageManagerRequest = (targetSize:CGSize, contentMode:PHImageContentMode, options:PHImageRequestOptions?)

public extension PHCachingImageManager{
    func requestImage(for asset: PHAsset, request: PHImageManagerRequest, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        return requestImage(for: asset, targetSize: request.targetSize, contentMode: request.contentMode, options: request.options, resultHandler: resultHandler)
    }

    func startCachingImages(for assets: [PHAsset], request: PHImageManagerRequest) {
        startCachingImages(for: assets, targetSize: request.targetSize, contentMode: request.contentMode, options: request.options)
    }

    func stopCachingImages(for assets: [PHAsset], request: PHImageManagerRequest) {
        stopCachingImages(for: assets, targetSize: request.targetSize, contentMode: request.contentMode, options: request.options)
    }
}

