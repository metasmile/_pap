//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

enum ConvertableMediaType: Int, Decodable{
    case any
    case video
    case livephoto
    case gif
    case burst
    case timelapse
}

struct ConvertableDirection: Codable, Equatable {
    var from:ConvertableMediaType
    var to:ConvertableMediaType

    private enum CodingKeys: Int, CodingKey {
        case from
        case to
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from.rawValue, forKey: .from)
        try container.encode(to.rawValue, forKey: .to)
    }

    public static func == (lhs: ConvertableDirection, rhs: ConvertableDirection) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
}


//TODO: convert option
protocol ConverterWorker {

    init()

    static var direction:ConvertableDirection {get}

    func convert(asset:AppAsset, _ async: AsyncManualSignalable) -> Any?

    func isSupported(asset:AppAsset) -> Bool
}
/*
    VideoConverter
*/
protocol VideoConverter: ConverterWorker{}

extension VideoConverter{
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .video)
    }
}

struct VideoConverter_Gif: VideoConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.gif, to:.video) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.uniformTypeIdentifier == UTI.GIF
    }
}

struct VideoConverter_Burst: VideoConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.video) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .burst
    }
}

struct VideoConverter_LivePhoto: VideoConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.video) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var exportedlivePhoto: PHLivePhoto?

        async.begin()

        let livePhotoOptions = PHLivePhotoRequestOptions()

        livePhotoOptions.deliveryMode = .highQualityFormat
        let req_livephoto = PHImageManager.default().requestLivePhoto(for: asset.asset
                , targetSize: .zero
                , contentMode: .default
                , options: livePhotoOptions
                , resultHandler: { livePhoto, info in

            exportedlivePhoto = livePhoto
            async.end()

        })
        asset.requestIDs.append(PHAssetRequestID(forImage: req_livephoto))
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
        asset.requestIDs.append(PHAssetRequestID(forResourceData: req_data))
        async.waitUntilEnd()

        return resultURL
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .burst
    }
}

/*
    GifConverter
*/
protocol GifConverter: ConverterWorker{}

extension GifConverter{
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .gif)
    }
}

struct GifConverter_Video: GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.video, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

struct GifConverter_LivePhoto: GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .livePhoto
    }
}

struct GifConverter_Timelapse: GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.timelapse, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}

struct GifConverter_Burst: GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .burst
    }
}


/*
    LivePhotoConverter
*/

protocol LivePhotoConverter: ConverterWorker{}
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
    static var direction: ConvertableDirection { return ConvertableDirection(from:.video, to:.livephoto) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

