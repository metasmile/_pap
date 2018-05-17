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
        let param = ConverterBurstImageExtractParam(targetSize: source.asset.pixelSize, imageQuality: 0.8, contentMode: PHImageContentMode.aspectFit)
        
        if let urls = self.extractBurstImageURLs(source: source, param: param, async){
            if let videoURL = buildVideo(urls: urls, async) {
                async.begin()
                
                var result: (imageURL: URL, pairedVideoURL: URL)?
                
                LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0, completion:{
                    success, imageURL, pairedVideoURL, error in
                    if let imageURL = imageURL, let pairedVideoURL = pairedVideoURL {
                        result = (imageURL, pairedVideoURL)
                    }
                    
                    async.end()
                })
                
                async.waitUntilEnd()
                
                return result
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
        if let videoURL = self.extractVideoFileURL(source: source, async) {
            async.begin()
            
            var result: (imageURL: URL, pairedVideoURL: URL)?
            
            LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0, completion:{
                success, imageURL, pairedVideoURL, error in
                if let imageURL = imageURL, let pairedVideoURL = pairedVideoURL {
                    result = (imageURL, pairedVideoURL)
                }
                
                async.end()
            })
            
            async.waitUntilEnd()
            
            return result
        }
        else {
            return nil
        }
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video
    }
}

