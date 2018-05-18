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

        if let urls = extractImageURLsFromGIFData(asset:source.asset, async), urls.count > 0{

            let totalDuration = urls.map { $0.frameDelay }.reduce(0, +)
            let defaultFps = Int32(Double(urls.count-1)/totalDuration)

            var photoURL: URL?
            var movieURL: URL?
            
            async.begin()
            LivePhotoWriter().writeLivePhotoFromImages(photoPaths: urls.map { $0.url.path }, indexOfTitle: 0, progress: nil, fps: defaultFps) { (success, imageURL, pairedVideoURL, error) in
                
                if success {
                    photoURL = imageURL
                    movieURL = pairedVideoURL
                }
                
                async.end()
            }

            async.waitUntilEnd()
            
            return [photoURL, movieURL].compactMap { $0 }
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

            var preferredOutputSize:CGSize = .zero
            if let firstImageUrl = urls.first?.url, let firstImageSize = UIImage(contentsOfFile: firstImageUrl.path)?.size{
                preferredOutputSize = firstImageSize.aspectFit(in: LivePhotoWritableMaximumStandardSize)
            }

            if let videoURL = buildVideo(urls: urls, outputSize: preferredOutputSize, async) {
                var photoURL: URL?
                var movieURL: URL?
                
                async.begin()

                LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0) { success, imageURL, pairedVideoURL, error in
                    if success {
                        photoURL = imageURL
                        movieURL = pairedVideoURL
                    }
                    async.end()
                }

                async.waitUntilEnd()

                return [photoURL, movieURL].compactMap { $0 }
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
        if let videoURL = self.extractVideoFileURL(source: source, async){

            var photoURL: URL?
            var movieURL: URL?
            
            async.begin()
            
            LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0) { success, imageURL, pairedVideoURL, error in
                if success {
                    photoURL = imageURL
                    movieURL = pairedVideoURL
                }
                async.end()
            }
            
            async.waitUntilEnd()
            
            return [photoURL, movieURL].compactMap { $0 }
        }
        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video
    }
}

