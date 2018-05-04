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
            return worker.isSupported(source: asset) ? worker : nil
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

    func convert(source:AppAsset, _ async: AsyncManualSignalable) -> Any?

    func isSupported(source:AppAsset) -> Bool
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
    Create Video with a URL
*/
extension Converter{

    func buildVideo(sources:[URL], fps:Int32, _ async: AsyncManualSignalable) -> URL?{
        return self.buildVideo(sources: sources.map { url -> String in
            assert(url.isFileURL)
            return url.path
        }, fps: fps, async)
    }

    func buildVideo(sources:[String], fps:Int32, _ async: AsyncManualSignalable) -> URL?{

        var videoUrl:URL?

        if sources.count > 0{
            async.begin()

            let builder = TimelapsVideoBuilder(imagePaths: sources)
            builder.fps = fps
            builder.build({ _ in  }, success: { url in

                videoUrl = url
                async.end()
            }, failure: { error in

                async.end()
            })

            async.waitUntilEnd()
        }

        return videoUrl
    }
}


/*
    Extract Burst Image URLs
*/
struct ConverterBurstImageExtractParam {
    let filenamePrefix:String = String(describing: ConverterBurstImageExtractParam.self)
    let targetSize:CGSize = CGSize(width: 1920, height: 1920)
    let imageQuality:CGFloat = CGFloat(0.7)
}

extension Converter{

    func extractBurstImageURLs(source:AppAsset, param: ConverterBurstImageExtractParam = ConverterBurstImageExtractParam(), _ async: AsyncManualSignalable) -> [URL]{

        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAllBurstAssets = true
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let targetSize = param.targetSize
        let imageQuality = param.imageQuality

        var urls = [URL]()

        let fetchedAsset = PHAsset.fetchAssets(withBurstIdentifier: source.asset.burstIdentifier ?? "", options: fetchOptions)
        fetchedAsset.enumerateObjects { (asset:PHAsset, idx, stop) in

            async.begin()

            var resultUrl: URL? = nil
            let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: PHAsset.highQualityImageRequestOptions) { (image, info) in
                guard let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, !isDegraded else { return }
                guard let image = image else { return }

                if let data = UIImageJPEGRepresentation(image, CGFloat(imageQuality)){

                    let url = "\(param.filenamePrefix)_\(idx)".asURLOfFileNameInTemporaryDirectory!

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

        return urls
    }
}