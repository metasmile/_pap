//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

enum ConvertingType: String, Decodable{
    case any = "Any"
    case jpeg = "Image (.jpg)" // e.g. - jpeg -> gif/livephoto/video == sliced Panorama -> play left to right
    case png = "Image (.png)"
    case png_screenshot = "Screenshot Image" // e.g. screenshots
    case heif = "Image (.heif)"
    case mov = "Video (.mov)"
    case mov_timelapse = "Timelapse Video"
    case mp4 = "Video (.mp4)"
    case wav = "Sound (.wav)" // e.g. mov -> sound -> wav or mp4
    case mp3 = "Audio (.mp3)"
    case livephoto = "Live Photo"
    case gif = "GIF"
    case burst = "Burst Photos"
}

struct ConvertingDirection: Codable, Equatable {
    var from: ConvertingType
    var to: ConvertingType

    var identifier:String{
        return from.rawValue + to.rawValue
    }

    private enum CodingKeys: Int, CodingKey {
        case from
        case to
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from.rawValue, forKey: .from)
        try container.encode(to.rawValue, forKey: .to)
    }

    public static func == (lhs: ConvertingDirection, rhs: ConvertingDirection) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
}

protocol Converter {

    init()

    static var direction: ConvertingDirection {get}

    static func canPerformWith(source:AppAsset) -> Bool

    func convert(source:AppAsset, _ async: AsyncManualSignalable) -> Any?
}

struct ConverterSpec{
    static func acquireInstance(collection:[Converter.Type], direction: ConvertingDirection, asset:AppAsset) -> Converter?{

        let matchedWorkers = collection.filter { $0.direction==direction }
        assert(matchedWorkers.count==1, "Duplicated converter worker direction found. \(matchedWorkers)")

        if let worker = matchedWorkers.first, worker.canPerformWith(source: asset) {
            return worker.init()
        }

        return nil
    }
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
    var targetSize:CGSize = CGSize(width: 1920, height: 1920)
    var imageQuality:CGFloat = CGFloat(0.7)
    var contentMode: PHImageContentMode = .aspectFit
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
            
            let response = asset.requestImage(targetSize: targetSize, contentMode: param.contentMode, options: PHAsset.highQualityImageRequestOptions)

            var resultUrl: URL? = nil
            if let image = response.1, let data = UIImageJPEGRepresentation(image, CGFloat(imageQuality)) {
                let url = "\(param.filenamePrefix)_\(UUID().uuidString)".asURLInTemporaryDirectory!
                
                do {
                    try data.write(to: url)
                    resultUrl = url
                } catch _ {}
            }
            source.requestIDs.append(PHAssetRequestID(forImage: response.0))

            if let resultUrl = resultUrl {
                urls.append(resultUrl)
            }
            
            async.end()
        }
        
        async.waitUntilEnd()

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
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        async.begin()
        PHImageManager.default().requestImageData(for: asset, options: options) { data, uti, orientation, info in
            guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
            if let data = data, let urls = data.extractAnimatedImageURLsAsGIF(){
                resultUrls = urls
            }
            async.end()
        }
        async.waitUntilEnd()
        return resultUrls
    }
}
