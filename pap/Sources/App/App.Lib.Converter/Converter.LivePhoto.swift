//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

protocol LivePhotoConverter: Converter {}
extension LivePhotoConverter {
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .livephoto)
    }
}

struct LivePhotoConverter_Gif: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.gif, to:.livephoto) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        if let urls = extractImageURLsFromGIFData(asset:source.asset, async){

            //(frames per second) = (1000) / (frame delay)

            let defaultFps = 30//Int32(1000/(urls.first?.frameDelay ?? 0.2))

            async.begin()
            LivePhotoWriter().saveLivePhotoFromImages(paths: urls.map { $0.url.path }, indexOfTitle: 0, progress: nil, fps: 10, saved:  { success, s, error in

                async.end()

            }, andFetched: nil)

            async.waitUntilEnd()

            return nil
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
        let param = ConverterBurstImageExtractParam(targetSize: source.asset.pixelSize, imageQuality: 0.8, contentMode: PHImageContentMode.aspectFit)
        
        if let urls = self.extractBurstImageURLs(source: source, param: param, async){

            if let videoURL = buildVideo(urls: urls, async) {

                var result: (imageURL: URL, pairedVideoURL: URL)?

                async.begin()

                LivePhotoWriter().saveLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0, saved: { success, s, error in
                    async.end()
                }, andFetched: nil)

                async.waitUntilEnd()

                return nil
            }
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

