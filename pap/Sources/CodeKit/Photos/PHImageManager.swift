//
// Created by BLACKGENE on 22.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

public typealias PHAssetRequestOption = (targetSize:CGSize, contentMode:PHImageContentMode, options:PHImageRequestOptions?)

public extension PHCachingImageManager{
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

