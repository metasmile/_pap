//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO

protocol MovConverter: Converter {}

extension MovConverter {
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .mov)
    }
}

struct MovConverter_Gif: MovConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.gif, to:.mov) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var paths:[String]?

        async.begin()
        PHImageManager.default().requestImageData(for: source.asset, options: nil) { data, s, orientation, dictionary in
            if let data = data, let urls = data.extractAnimatedImageURLsAsGIF(){
                paths = urls.map { $0.path }
            }
            async.end()
        }
        async.waitUntilEnd()

        let fps:Int32 = 15

        if let paths = paths{
            return self.buildVideo(paths: paths, fps: fps, async)
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.uniformTypeIdentifier == UTCoreTypes.GIF
    }
}

struct MovConverter_Burst: MovConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.mov) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        if let urls = self.extractBurstImageURLs(source: source, async){
            return self.buildVideo(urls: urls, fps: 15, async)
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
}

struct MovConverter_LivePhoto: MovConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.mov) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var exportedlivePhoto: PHLivePhoto?

        async.begin()

        let livePhotoOptions = PHLivePhotoRequestOptions()

        livePhotoOptions.deliveryMode = .highQualityFormat
        let req_livephoto = PHImageManager.default().requestLivePhoto(for: source.asset
                , targetSize: .zero
                , contentMode: .default
                , options: livePhotoOptions
                , resultHandler: { livePhoto, info in

            exportedlivePhoto = livePhoto
            async.end()

        })
        source.requestIDs.append(PHAssetRequestID(forImage: req_livephoto))
        async.waitUntilEnd()

        guard let livePhoto = exportedlivePhoto else {
            return nil
        }

        let resources = PHAssetResource.assetResources(for: livePhoto)

        guard let videoResource = resources.first(where: { $0.type == PHAssetResourceType.pairedVideo }),
              let _ = resources.first(where: { $0.type == PHAssetResourceType.photo }) else {
            return nil
        }

        var videoData = Data()
        var resultURL:URL?

        async.begin()

        let req_data = PHAssetResourceManager.default().requestData(for: videoResource, options: nil, dataReceivedHandler: { (data) in
            videoData.append(data)

        }) { (error) in
            if error == nil{
                let pairedVideoFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("pairedVideo.mov")
                try? videoData.write(to: pairedVideoFileURL, options: Data.WritingOptions.atomicWrite)

                resultURL = pairedVideoFileURL
            }
            async.end()
        }
        source.requestIDs.append(PHAssetRequestID(forResourceData: req_data))
        async.waitUntilEnd()

        return resultURL
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
}