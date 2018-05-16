//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

protocol LivePhotoConverter: Converter {}
extension LivePhotoConverter{
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .livephoto)
    }
}

struct LivePhotoConverter_Gif: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.gif, to:.livephoto) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        let urls = extractImageURLsFromGIFData(asset:source.asset, async)

        if let urls = urls{
            //TODO: must perform "saveLivePhoto"
            return self.createLivePhoto(fromImagePaths: urls.map { $0.url.path }, async)
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .animatedGIF
    }

}

struct LivePhotoConverter_Burst: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.burst, to:.livephoto) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        if let urls = self.extractBurstImageURLs(source: source, async){
            //TODO: must perform "saveLivePhoto"
            return self.createLivePhoto(fromImageURLs: urls.map { $0.url }, async)
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
}

struct LivePhotoConverter_Video: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.livephoto) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        var succeed = false
        if let videoURL = self.extractVideoFileURL(source: source, async){

            async.begin()

            LivePhotoWriter().saveLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0, saved: { success, s, error in
                succeed = success

                async.end()
            }, andFetched: nil)

        }else{
            async.end()
        }

        async.waitUntilEnd()
        //FIXME: succeed always == false
        return nil//succeed ? ConverterVoidReturnValue : nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video
    }
}

