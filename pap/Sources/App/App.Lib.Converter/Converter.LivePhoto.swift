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

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {

        if let urls = extractImageURLsFromGIFData(asset:source.asset, async), urls.count > 0{

            let totalDuration = urls.map { $0.frameDelay }.reduce(0, +)
            let defaultFps = Int32(Double(urls.count-1)/totalDuration)
            
            var result = PHAssetResourceFinalizingOutput()
            
            async.begin()
            LivePhotoWriter().writeLivePhotoFromImages(photoPaths: urls.map { $0.url.path }, indexOfTitle: 0, progress: nil, fps: defaultFps) { (success, photoURL, videoURL, error) in
                if let photoURL = photoURL {
                    result.resources.append((resourceType: .photo, url: photoURL))
                }
                
                if let videoURL = videoURL {
                    result.resources.append((resourceType: .pairedVideo, url: videoURL))
                }
                
                async.end()
            }

            async.waitUntilEnd()

            return result
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .animatedGIF
    }
    
    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumAnimated
    }

}

struct LivePhotoConverter_Burst: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.burst, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {
        let targetSize = AVMakeRect(aspectRatio: source.asset.pixelSize, insideRect: CGRect(origin: .zero, size: LivePhotoWritableMaximumStandardSize)).size
        //TODO: quality
        let param = ConverterBurstImageExtractParam(targetSize: targetSize, imageQuality: 0.8, contentMode: PHImageContentMode.aspectFit)
        
        if let urls = self.extractBurstImageURLs(source: source, param: param, async){
            if let videoURL = buildVideo(urls: urls, outputSize: targetSize, async) {
                var result = PHAssetResourceFinalizingOutput()
                
                async.begin()
                LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0) { (success, photoURL, videoURL, error) in
                    if let photoURL = photoURL {
                        result.resources.append((resourceType: .photo, url: photoURL))
                    }
                    
                    if let videoURL = videoURL {
                        result.resources.append((resourceType: .pairedVideo, url: videoURL))
                    }
                    
                    async.end()
                }
                async.waitUntilEnd()
                
                return result
            }
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
    
    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumBursts
    }
}

struct LivePhotoConverter_Mov: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {
        if let videoURL = self.extractVideoFileURL(source: source, async){
            var result = PHAssetResourceFinalizingOutput()
            
            async.begin()
            LivePhotoWriter().writeLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0) { (success, photoURL, videoURL, error) in
                if let photoURL = photoURL {
                    result.resources.append((resourceType: .photo, url: photoURL))
                }
                
                if let videoURL = videoURL {
                    result.resources.append((resourceType: .pairedVideo, url: videoURL))
                }
                
                async.end()
            }
            async.waitUntilEnd()
            
            return result
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video
    }
    
    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumUserLibrary
    }
    
    static var performMediaType: PHAssetMediaType? {
        return .video
    }
}

struct LivePhotoConverter_Timelapse: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {
        let converter = LivePhotoConverter_Mov()
        return converter.convert(source: source, async)
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.videoTimelapse)
    }

    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumUserLibrary
    }

    static var performMediaType: PHAssetMediaType? {
        return .video
    }
}
