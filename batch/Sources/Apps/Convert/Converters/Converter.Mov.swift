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
            return self.buildVideo(sources: paths, fps: fps, async)
        }

        return nil
    }

    func isSupported(source: AppAsset) -> Bool {
        return source.asset.uniformTypeIdentifier == UTI.GIF
    }
}

struct MovConverter_Burst: MovConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.mov) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAllBurstAssets = true
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]


        let targetSize = CGSize(width: 1920, height: 1920)
        let imageQuality = 0.7
        let fps:Int32 = 15
        var urls = [URL]()

        let fetchedAsset = PHAsset.fetchAssets(withBurstIdentifier: source.asset.burstIdentifier ?? "", options: fetchOptions)
        fetchedAsset.enumerateObjects { (asset:PHAsset, idx, stop) in

            async.begin()

            var resultUrl: URL? = nil
            let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: PHAsset.highQualityImageRequestOptions) { (image, info) in
                guard let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, !isDegraded else { return }
                guard let image = image else { return }

                if let data = UIImageJPEGRepresentation(image, CGFloat(imageQuality)){
                    let url = "MovConverter_Burst_\(idx)".asURLOfFileNameInTemporaryDirectory!

                    do{
                        try data.write(to: url)
                        resultUrl = url
                    }catch _ {}
                }

                async.end()
            }
            source.requestIDs.append(PHAssetRequestID(forImage: imageRequestID))

            async.waitUntilEnd()

            if let resultUrl = resultUrl {
                urls.append(resultUrl)
            }
        }

        return self.buildVideo(sources: urls, fps: fps, async)
    }

    func isSupported(source: AppAsset) -> Bool {
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

    func isSupported(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
}