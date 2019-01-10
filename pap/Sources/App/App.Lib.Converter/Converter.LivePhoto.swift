//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

protocol LivePhotoConverter: Converter, ConverterCapability {}
extension LivePhotoConverter {
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .livephoto)
    }
}

struct LivePhotoConverter_Gif: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.gif, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {

        if let urls = extractImageURLsFromGIFData(asset:source.asset, async), urls.count > 0{

            let totalDuration = urls.map { $0.frameDelay }.reduce(0, +)
            let defaultFps = Int32(Double(urls.count-1)/totalDuration)
            
            var result: [PHAssetEditingResultItem]?
            
            async.begin()
            LivePhotoWriter().writeLivePhotoFromImages(photoPaths: urls.map { $0.url.path }, indexOfTitle: 0, progress: progressHandler, fps: defaultFps) { (success, photoURL, videoURL, error) in
                if let photoURL = photoURL, let videoURL = videoURL {
                    result = [
                        PHAssetEditingResultItem(photoURL, .photo),
                        PHAssetEditingResultItem(videoURL, .pairedVideo),
                    ]
                }
                async.end()
            }

            async.waitUntilEnd()

            return result
        }

        return nil
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.imageType == .animatedGIF
    }

}

struct LivePhotoConverter_Burst: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.burst, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        let targetSize = AVMakeRect(aspectRatio: source.asset.pixelSize, insideRect: CGRect(origin: .zero, size: LivePhotoWritableMaximumStandardSize)).size
        //TODO: quality
        let param = ConverterBurstImageExtractParam(targetSize: targetSize, imageQuality: 0.8, contentMode: PHImageContentMode.aspectFit)
        
        if let urls = self.extractBurstImageURLs(source: source, param: param, async){
            if let videoURL = buildVideo(urls: urls, outputSize: targetSize, progressHandler: progressHandler, async) {
                
                var result: [PHAssetEditingResultItem]?
                
                async.begin()
                LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0) { (success, photoURL, videoURL, error) in
                    if let photoURL = photoURL, let videoURL = videoURL {
                        result = [
                            PHAssetEditingResultItem(photoURL, .photo),
                            PHAssetEditingResultItem(videoURL, .pairedVideo),
                        ]
                    }
                    async.end()
                }
                
                async.waitUntilEnd()

                return result
            }
        }

        return nil
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.imageType == .burst
    }
}

struct LivePhotoConverter_Mov: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        
        guard let videoURL = self.extractVideoFileURL(source: source, AsyncSignal()) else { return nil }
        
        var result: [PHAssetEditingResultItem]?
        
        async.begin()
        DispatchQueue(label: #function, qos: .utility).async {
            LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0) { (success, photoURL, videoURL, error) in
                if let photoURL = photoURL, let videoURL = videoURL {
                    result = [
                        PHAssetEditingResultItem(photoURL, .photo),
                        PHAssetEditingResultItem(videoURL, .pairedVideo),
                    ]
                }
                async.end()
            }
        }
        async.waitUntilEnd()
        
        return result
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.mediaType == .video && asset.duration < 15
    }
}

struct LivePhotoConverter_Timelapse: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        let converter = LivePhotoConverter_Mov()
        return converter.convert(source: source, cancellation: cancellation, progressHandler: progressHandler, async)
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.mediaSubtypes.contains(.videoTimelapse)
    }
}
