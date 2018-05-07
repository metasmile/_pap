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

    func buildVideo(urls:[URL], fps:Int32, _ async: AsyncManualSignalable) -> URL?{
        return self.buildVideo(paths: urls.mapAsPath, fps: fps, async)
    }

    func buildVideo(paths:[String], fps:Int32, _ async: AsyncManualSignalable) -> URL?{

        var videoUrl:URL?

        if paths.count > 0{
            async.begin()

            let builder = TimelapsVideoBuilder(imagePaths: paths)
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


    public func extractVideoFileURL(source:AppAsset, options: PHVideoRequestOptions? = nil, _ async: AsyncManualSignalable) -> URL? {

        var videoURL:URL?
        guard let requestId = source.asset.exportVideoFile(options: options, progressHandler: nil, completionHandler: { success, url, mimetype in
            videoURL = success ? url : nil
            async.end()

        }) else{
            return nil
        }

        async.begin()
        source.requestIDs.append(PHAssetRequestID(forImage: requestId))

        async.waitUntilEnd()
        return videoURL
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

    func extractBurstImageURLs(source:AppAsset, param: ConverterBurstImageExtractParam = ConverterBurstImageExtractParam(), _ async: AsyncManualSignalable) -> [URL]?{

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

                    let url = "\(param.filenamePrefix)_\(idx)".asURLInTemporaryDirectory!

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

        return urls.count>0 ? urls : nil
    }
}

/*
  Create Live Photos from URLs or Paths
*/

extension Converter{
    func createLivePhoto(fromImageURLs:[URL], fps:Int32=30, _ async: AsyncManualSignalable) -> PHLivePhoto?{
        return self.createLivePhoto(fromImagePaths: fromImageURLs.mapAsPath, fps: fps, async)
    }

    func createLivePhoto(fromImagePaths:[String], fps:Int32=30, _ async: AsyncManualSignalable) -> PHLivePhoto?{
        var result:PHLivePhoto?

        async.begin()

        LivePhotoWriter().createLivePhotoFromImages(paths: fromImagePaths, indexOfTitle: 0, progress: nil, fps: fps) { photo in
            result = photo
            async.end()
        }
        async.waitUntilEnd()

        return result
    }

    func createLivePhoto(fromVideoPath:String, timeLocationOfTitle:Double=0, _ async: AsyncManualSignalable) -> PHLivePhoto?{
        var result:PHLivePhoto?

        async.begin()

        LivePhotoWriter().createLivePhotoFromVideo(videoPath: fromVideoPath, timeLocationOfTitle: 0) { photo in
            result = photo
            async.end()
        }

        async.waitUntilEnd()

        return result
    }
}


/*
   Create GIF URLs from PHAsset data
 */

extension Converter{

    func extractImageURLsFromGIFData(asset:PHAsset, _ async: AsyncManualSignalable) -> [URL]?{
        var resultUrls:[URL]?

        async.begin()
        PHImageManager.default().requestImageData(for: asset, options: nil) { data, s, orientation, dictionary in
            if let data = data, let urls = data.extractAnimatedImageURLsAsGIF(){
                resultUrls = urls
            }
            async.end()
        }
        async.waitUntilEnd()
        return resultUrls
    }
}
