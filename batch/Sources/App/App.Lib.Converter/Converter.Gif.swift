//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

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
    
    func sizeWithAspectRatio() -> CGSize {
        if aspectRatio < 1 {
            return CGSize(width: Int(size * aspectRatio), height: Int(size))
        }
        else {
            return CGSize(width: Int(size), height: Int(size / aspectRatio))
        }
    }
    
    func urlWithDirection(urls: [URL]) -> [URL] {
        return GifConverterDefaultOption.URLs(urls: urls, with: direction)
    }
    
    static func URLs(urls: [URL], with direction: Int) -> [URL] {
        if urls.count > 1 {
            switch direction {
            case 1: return urls.reversed()
            case 2: return urls + urls[1...].reversed()[1...]
            default: break
            }
        }
        return urls
    }
}


protocol GifConverter: Converter {}

extension GifConverter{
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .gif)
    }
}

class GifConverter_Jpeg: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.jpeg, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .stillImage
    }
}

class GifConverter_Mov: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video
    }
}

class GifConverter_LivePhoto: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.livephoto, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        let extractMovieTask = AsyncSignal()
        if let videoURL = MovConverter_LivePhoto().convert(source: source, extractMovieTask) as? URL {
            async.begin()
            
            let video = AVAsset(url: videoURL)
            
            let gifOptions = options ?? GifConverterDefaultOption(aspectRatio: Double(source.asset.pixelSize.width / source.asset.pixelSize.height), contentMode: 0, frameDelay: 100, size: 480, direction: 0, gifQuality: 0.5, loopCount: 0)
            
            let imageGenerator = AVAssetImageGenerator(asset: video)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceBefore = kCMTimeZero
            imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
            imageGenerator.maximumSize = gifOptions.sizeWithAspectRatio()
            
            var times = [NSValue]()
            let tick = CMTimeMultiplyByFloat64(video.duration, Double(gifOptions.frameDelay) / 1000)
            var time = kCMTimeZero
            while time <= video.duration {
                times.append(NSValue(time: time))
                time = CMTimeAdd(time, tick)
            }
            
            var imageFiles = [URL]()
            imageGenerator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, cgImage, actualTime, result, error) in
                if let cgImage = cgImage {
                    imageFiles.append(LocalCachedAsset(image: UIImage(cgImage: cgImage), targetSize: gifOptions.sizeWithAspectRatio(), imageQuality: CGFloat(gifOptions.gifQuality), contentMode: PHImageContentMode(rawValue: gifOptions.contentMode) ?? .aspectFit).imageFileURL)
                }
                
                if requestedTime == times.last?.timeValue {
                    async.end()
                }
            }
            
            async.waitUntilEnd()
            
            return UIImageGIFRepresentationURL(with: gifOptions.urlWithDirection(urls: imageFiles), loopCount: gifOptions.loopCount, frameDelay: Double(gifOptions.frameDelay) / 1000)
        }
        
        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .livePhoto
    }
}

class GifConverter_Timelapse: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}

class GifConverter_Burst: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.burst, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        let gifOptions = options ?? GifConverterDefaultOption(aspectRatio: Double(source.asset.pixelSize.width / source.asset.pixelSize.height), contentMode: 0, frameDelay: 100, size: 480, direction: 0, gifQuality: 0.5, loopCount: 0)
        let param = ConverterBurstImageExtractParam(targetSize: gifOptions.sizeWithAspectRatio(), imageQuality: CGFloat(gifOptions.gifQuality), contentMode: PHImageContentMode(rawValue: gifOptions.contentMode) ?? PHImageContentMode.aspectFit)
        
        guard let urls = extractBurstImageURLs(source: source, param: param, async) else { return nil }
        return UIImageGIFRepresentationURL(with: gifOptions.urlWithDirection(urls: urls), loopCount: gifOptions.loopCount, frameDelay: Double(gifOptions.frameDelay) / 1000)
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
}

struct LocalCachedAsset {
    public var asset: PHAsset?
    public var imageFileURL: URL
    
    init(_ asset: PHAsset? = nil, image: UIImage, targetSize: CGSize, imageQuality: CGFloat, contentMode: PHImageContentMode = .aspectFit) {
        let imageToWrite: UIImage
        if targetSize == image.size {
            imageToWrite = image
        }
        else {
            imageToWrite = UIGraphicsImageRenderer(size: targetSize, format: image.imageRendererFormat).imageWithCurrentContext { (cgContext) in
                if contentMode == .aspectFit {
                    UIColor.white.setFill()
                    cgContext.fill(CGRect(origin: .zero, size: targetSize))
                    image.draw(in: AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: .zero, size: targetSize)))
                }
                else {
                    let scale = image.size.width > image.size.height ? targetSize.height / image.size.height : targetSize.width / image.size.width
                    let scaledSize = image.size.applying(CGAffineTransform(scaleX: scale, y: scale))
                    image.draw(in: CGRect(origin: CGPoint(x: (targetSize.width - scaledSize.width) / 2, y: (targetSize.height - scaledSize.height) / 2), size: scaledSize))
                }
            } ?? image
        }
        
        var data: Data?
        var fileExtension = "jpg"
        switch asset?.uniformTypeIdentifier {
        case UTCoreTypes.PNG?:
            data = UIImagePNGRepresentation(imageToWrite)
            fileExtension = "png"
        default:
            data = UIImageJPEGRepresentation(imageToWrite, imageQuality)
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: LocalCachedAsset.self))_\(UUID().uuidString).\(fileExtension)")
        try? data?.write(to: url)
        
        self.asset = asset
        self.imageFileURL = url
    }
}
