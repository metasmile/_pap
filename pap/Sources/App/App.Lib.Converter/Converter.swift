//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

/*
 if converter needs only internally-finishing process, should return `ConverterVoidReturnValue`
 */
public typealias ConverterVoidReturnType = Int
public let ConverterVoidReturnValue = ConverterVoidReturnType.max

enum ConvertingType: String, Decodable{
    case any = "Any"
    case jpeg = "Image (.jpg)" // e.g. - jpeg -> gif/livephoto/video == sliced Panorama -> play left to right
    case png = "Image (.png)"
    case png_screenshot = "Screenshot Image" // e.g. screenshots
    case heif = "Image (.heif)"
    case mov = "Video"
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

struct ConvertingQuality: Codable {
    var convertingDirection: ConvertingDirection
    var qualityType: ConverterQualityPreset
    
    private enum CodingKeys: Int, CodingKey {
        case convertingDirection
        case qualityType
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(convertingDirection, forKey: .convertingDirection)
        try container.encode(qualityType.rawValue, forKey: .qualityType)
    }
}

enum ConverterQualityPreset: String, Decodable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case original = "Original"

    static var all:[ConverterQualityPreset]{
        return [.low, .medium, .high, .original]
    }

    static var originalExcluded:[ConverterQualityPreset]{
        return [.low, .medium, .high]
    }

    static var originalOnly:[ConverterQualityPreset]{
        return [.original]
    }
}

protocol Converter {

    init()

    static var direction: ConvertingDirection {get}

    static func canPerformWith(asset: PHAsset) -> Bool

    func convert(source:AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]?
}

protocol ConverterCapability{
    static var supportedPresets: [ConverterQualityPreset] {get}
}

extension ConverterCapability{
    static var supportedPresets: [ConverterQualityPreset] {
        return [ConverterQualityPreset.medium]
    }
}

struct ConverterSpec{
    static func acquireInstance(collection:[Converter.Type], direction: ConvertingDirection, asset:AppAsset) -> Converter?{

        let matchedConverters = collection.filter { $0.direction==direction }
        assert(matchedConverters.count==1, "Duplicated converter worker direction found. \(matchedConverters)")

        if let worker = matchedConverters.first, worker.canPerformWith(asset: asset.asset) {
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

    func buildVideo(imageUrls:[URL], fps:Int32?=nil, _ async: AsyncWaitSignalable) -> URL?{
        return self.buildVideo(imagePaths: imageUrls.mapAsPath, fps: fps, async)
    }

    func buildVideo(imagePaths:[String], fps:Int32?=nil, outputSize: CGSize = .zero, _ async: AsyncWaitSignalable) -> URL?{

        var videoUrl:URL?

        if imagePaths.count > 0{
            async.begin()

            let builder = TimelapsVideoBuilder(imagePaths: imagePaths)
            if let fps = fps{
                builder.fps = fps
            }
            builder.preferredOutputSize = outputSize
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
    
    func buildVideo(urls:[(url: URL, frameDelay: Double)], outputSize: CGSize? = nil, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> URL?{
        var videoUrl:URL?
        
        if urls.count > 0{
            async.begin()
            
            DispatchQueue(label: #function + #file, qos: .utility).async {
                let builder = TimelapsVideoBuilder(imagePaths: urls.map { $0.url.path })
                if let outputSize = outputSize {
                    builder.preferredOutputSize = outputSize
                }
                
                builder.frameDelayEachImages = Dictionary(uniqueKeysWithValues: urls.map { url -> (String, Double) in
                    (url.url.path, url.frameDelay)
                })
                
                builder.build(progressHandler ?? { _ in }, success: { url in
                    videoUrl = url
                    async.end()
                }, failure: { error in
                    
                    async.end()
                })
            }
            
            async.waitUntilEnd()
        }
        
        return videoUrl
    }

    public func extractVideoFileURL(source:AppAsset, options: PHVideoRequestOptions? = nil, _ async: AsyncWaitSignalable) -> URL? {

        let options: PHVideoRequestOptions = PHVideoRequestOptions()
//        options.version = .original

    //TODO: quality
//        options.deliveryMode
//
//        case automatic // only apply with PHVideoRequestOptionsVersionCurrent // let us pick the quality (typ. PHVideoRequestOptionsDeliveryModeMediumQualityFormat for streamed AVPlayerItem or AVAsset, or PHVideoRequestOptionsDeliveryModeHighQualityFormat for AVAssetExportSession)
//
//        case highQualityFormat // best quality
//
//        case mediumQualityFormat // medium quality (typ. 720p), currently only supported for AVPlayerItem or AVAsset when streaming from iCloud (will systematically default to PHVideoRequestOptionsDeliveryModeHighQualityFormat if locally available)
//
//        case fastFormat // fa

        async.begin()

        var returningURL:URL?
        let requestId = PHImageManager.default().requestAVAsset(forVideo: source.asset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            if let urlAsset = asset as? AVURLAsset {
                returningURL = urlAsset.url as URL
            }
            async.end()
        })

        source.appendRequestId(PHAssetRequestID(forImage: requestId))
        async.waitUntilEnd()

        return returningURL
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

    func extractBurstImageURLs(source:AppAsset, param: ConverterBurstImageExtractParam = ConverterBurstImageExtractParam(), stabilizationMode: ImageAlignment.StabilizationMode = .none, _ async: AsyncWaitSignalable) -> [(url: URL, frameDelay: Double)]?{

        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAllBurstAssets = true
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let targetSize = param.targetSize
        let imageQuality = param.imageQuality

        var urls = [URL]()
        var intervals = [Double]()
        
        var interval = 0.1
        var assetDate: Date?
        
        var referenceImage: UIImage?

        let fetchedAsset = PHAsset.fetchAssets(withBurstIdentifier: source.asset.burstIdentifier ?? "", options: fetchOptions)
        fetchedAsset.enumerateObjects { (asset, idx, stop) in
            assetDate = autoreleasepool {

                let response = asset.requestImage(targetSize: targetSize, contentMode: param.contentMode, options: PHAsset.highQualityImageRequestOptions)

                var resultUrl: URL? = nil
                if let image = response.1?.stabilize(with: referenceImage, mode: stabilizationMode) {
                    referenceImage = image
                    
                    let data = image.jpegData(compressionQuality: CGFloat(imageQuality))

                    let identifier = "\(param.filenamePrefix)_\(asset.localIdentifierWithoutSplitter)_burst_\(idx)"
                    let url = FileURL.temp(identifier, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
                    do {
                        try data?.write(to: url)
                        resultUrl = url
                    } catch _ {}
                }
                source.appendRequestId(PHAssetRequestID(forImage: response.0))

                if let resultUrl = resultUrl {
                    urls.append(resultUrl)
                    
                    if let prevDate = assetDate {
                        interval = asset.creationDate?.timeIntervalSince(prevDate) ?? 0.1
                        intervals.append(interval)
                    }
                }
                return asset.creationDate
            }
        }
        
        intervals.append(interval)
        
        return (urls.count>0 && urls.count == intervals.count)
                ? urls.enumerated().map { ($0.element, intervals[$0.offset]) }
                : nil
    }
}

/*
  Create Live Photos from URLs or Paths
*/

extension Converter{
    func createLivePhoto(fromImageURLs:[URL], fps:Int32=30, _ async: AsyncWaitSignalable) -> PHLivePhoto?{
        return self.createLivePhoto(fromImagePaths: fromImageURLs.mapAsPath, fps: fps, async)
    }

    func createLivePhoto(fromImagePaths:[String], fps:Int32=30, _ async: AsyncWaitSignalable) -> PHLivePhoto?{
        var result:PHLivePhoto?

        async.begin()

        LivePhotoWriter().createLivePhotoFromImages(paths: fromImagePaths, indexOfTitle: 0, progress: nil, fps: fps) { photo in
            result = photo
            async.end()
        }
        async.waitUntilEnd()

        return result
    }

    func createLivePhoto(fromVideoPath:String, timeLocationOfTitle:Double=0, _ async: AsyncWaitSignalable) -> PHLivePhoto?{
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

    func extractImageURLsFromGIFData(asset:PHAsset, _ async: AsyncWaitSignalable) -> [(url: URL, frameDelay: Double)]?{
        var resultUrls:[(URL, Double)]?
        
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
