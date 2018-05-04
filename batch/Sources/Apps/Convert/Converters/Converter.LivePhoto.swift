//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

protocol LivePhotoConverter: Converter {}
extension LivePhotoConverter{
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .livephoto)
    }
}

struct LivePhotoConverter_Gif: LivePhotoConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.gif, to:.livephoto) }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var paths:[String]?

        async.begin()
        PHImageManager.default().requestImageData(for: asset.asset, options: nil) { data, s, orientation, dictionary in
            if let data = data, let urls = data.extractAnimatedImageURLsAsGIF(){
                paths = urls.map { $0.path }
            }
            async.end()
        }
        async.waitUntilEnd()


        if let paths = paths{
            var result:PHLivePhoto?

            async.begin()
            LivePhotoWriter().createLivePhotoFromImages(paths: paths, indexOfTitle: 0, progress: nil, fps: 30) { photo in
                result = photo
                async.end()
            }
            async.waitUntilEnd()

            return result
        }

        return nil
    }


}

struct LivePhotoConverter_Burst: LivePhotoConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.livephoto) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

struct LivePhotoConverter_Video: LivePhotoConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.mov, to:.livephoto) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

