//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

struct ConverterSpec {

    static func acquireWorker(collection:[Converter.Type], direction:ConvertableDirection, asset:AppAsset) -> Converter?{

        let matchedWorkers = collection.filter { $0.direction==direction }
        assert(matchedWorkers.count==1, "Duplicated converter worker direction found. \(matchedWorkers)")

        if let worker = type(of: matchedWorkers).init() as? Converter {
            return worker.isSupported(asset: asset) ? worker : nil
        }

        return nil
    }
}

enum ConvertableMediaType: Int, Decodable{
    case any
    case jpeg // e.g. - jpeg -> gif/livephoto/video == sliced Panorama -> play left to right
    case png // e.g. screenshots
    case heif
    case mov
    case mp4
    case wav // e.g. mov -> sound -> wav or mp4
    case mp3
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

protocol Converter {

    init()

    static var direction:ConvertableDirection {get}

    func convert(asset:AppAsset, _ async: AsyncManualSignalable) -> Any?

    func isSupported(asset:AppAsset) -> Bool
}

protocol OptionableConverter {
    associatedtype OptionType
    var options:OptionType? {set get}
}

class OptionableConverterBase<T>: OptionableConverter {
    typealias OptionType = T
    var options: OptionType?

    required init(){}
}


/*
    VideoConverter
*/
protocol MovConverter: Converter {}

extension MovConverter {
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .mov)
    }
}

struct MovConverter_Gif: MovConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.gif, to:.mov) }

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


        var videoUrl:URL?

        async.begin()
        if let paths = paths{
            let builder = TimelapsVideoBuilder(imagePaths: paths)
            builder.fps = 15
            builder.build({ _ in  }, success: { url in
                videoUrl = url
                async.end()
            }, failure: { error in
                async.end()
            })
        }
        async.waitUntilEnd()

        return videoUrl
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.uniformTypeIdentifier == UTI.GIF
    }
}

struct MovConverter_Burst: MovConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.mov) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .burst
    }
}

struct MovConverter_LivePhoto: MovConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.mov) }

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

/*
GifConverter-specific options
*/

struct GifConverterDefaultOption {
    var aspectRatio: Double
    var contentMode: Int
    var frameDelay: Int
    var size: Double
    var direction: Int
    var gifQuality: Double
    var loopCount: Int

    static var `default`: GifConverterDefaultOption {
        return GifConverterDefaultOption(
                aspectRatio: 0,
                contentMode: 0,
                frameDelay: 0,
                size: 0,
                direction: 0,
                gifQuality: 0,
                loopCount: 0
        )
    }

}


protocol GifConverter: Converter {}

extension GifConverter{
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .gif)
    }
}

class GifConverter_Jpeg: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.jpeg, to:.gif) }

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

class GifConverter_Mov: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.mov, to:.gif) }

        func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

class GifConverter_LivePhoto: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.gif) }


    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .livePhoto
    }
}

class GifConverter_Timelapse: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.timelapse, to:.gif) }

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}

class GifConverter_Burst: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.gif) }
    

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

protocol LivePhotoConverter: Converter {}
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
    static var direction: ConvertableDirection { return ConvertableDirection(from:.mov, to:.livephoto) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

