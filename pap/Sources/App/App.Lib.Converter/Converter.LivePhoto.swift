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

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        if let urls = extractImageURLsFromGIFData(asset:source.asset, async), urls.count > 0{

            let totalDuration = urls.map { $0.frameDelay }.reduce(0, +)
            let defaultFps = Int32(Double(urls.count-1)/totalDuration)

            var succeed = false
            async.begin()
            LivePhotoWriter().saveLivePhotoFromImages(paths: urls.map { $0.url.path }, indexOfTitle: 0, progress: nil, fps: defaultFps, saved:  { success, s, error in
                succeed = success
                async.end()
            }, andFetched: nil)

            async.waitUntilEnd()

            return succeed ? ConverterVoidReturnValue : nil
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .animatedGIF
    }

}

struct LivePhotoConverter_Burst: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.burst, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        let targetSize = AVMakeRect(aspectRatio: source.asset.pixelSize, insideRect: CGRect(origin: .zero, size: LivePhotoWritableMaximumStandardSize)).size
        //TODO: quality
        let param = ConverterBurstImageExtractParam(targetSize: targetSize, imageQuality: 0.8, contentMode: PHImageContentMode.aspectFit)
        
        if let urls = self.extractBurstImageURLs(source: source, param: param, async){
            if let videoURL = buildVideo(urls: urls, outputSize: targetSize, async) {

                async.begin()

                var succeed = false

                LivePhotoWriter().saveLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0, saved: { success, s, error in
                    succeed = success
                    async.end()

                }, andFetched: nil)

                async.waitUntilEnd()

                return succeed ? ConverterVoidReturnValue : nil
            }
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
}

struct LivePhotoConverter_Mov: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        var succeed = false

        if let videoURL = self.extractVideoFileURL(source: source, async){

            async.begin()

            LivePhotoWriter().saveLivePhotoFromVideo(videoPath: videoURL.path, timeLocationOfTitle: 0, saved: { success, s, error in
                succeed = success

                async.end()

            }, andFetched: nil)

            async.waitUntilEnd()
        }

        return succeed ? ConverterVoidReturnValue : nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video
    }
}

struct LivePhotoConverter_Timelapse: LivePhotoConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.livephoto) }

    static let supportedPresets = [ConverterQualityPreset.high]

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        let converter = LivePhotoConverter_Mov()
        return converter.convert(source: source, async)
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}
