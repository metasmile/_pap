//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

struct GifConverterDefaultOption {
    var aspectRatio: Double
    var contentMode: PHImageContentMode
    var frameDelay: Double
    var size: Double
    var direction: Int
    var gifQuality: Double
    var loopCount: Int
    var stabilizationMode: ImageAlignment.StabilizationMode

    static var `default`: GifConverterDefaultOption {
        return GifConverterDefaultOption(
                aspectRatio: 0,
                contentMode: .aspectFit,
                frameDelay: 0,
                size: 0,
                direction: 0,
                gifQuality: 0,
                loopCount: 0,
                stabilizationMode: .none
        )
    }
    
    static func preset(_ quality: ConverterQualityPreset, with asset: PHAsset) -> GifConverterDefaultOption {
        var optionPreset = GifConverterDefaultOption.default
        optionPreset.aspectRatio = Double(asset.pixelSize.width / asset.pixelSize.height)
        
        switch quality {
        case .low:
            optionPreset.gifQuality = 0.7
            optionPreset.size = 320
            optionPreset.frameDelay = 1 / 15
        case .medium:
            optionPreset.gifQuality = 0.7
            optionPreset.size = 480
            optionPreset.frameDelay = 1 / 15
        case .high:
            optionPreset.gifQuality = 0.7
            optionPreset.size = 640
            optionPreset.frameDelay = 1 / 15
        case .original:
            optionPreset.gifQuality = 0.8
            optionPreset.size = Double(asset.pixelWidth)
        }
        
        return optionPreset
    }
    
    func sizeWithAspectRatio() -> CGSize {
        if aspectRatio < 1 {
            return CGSize(width: Int(size * aspectRatio), height: Int(size))
        }
        else {
            return CGSize(width: Int(size), height: Int(size / aspectRatio))
        }
    }
    
    func urlWithDirection<T>(urls: [T]) -> [T] {
        return GifConverterDefaultOption.URLs(urls: urls, with: direction)
    }
    
    static func URLs<T>(urls: [T], with direction: Int) -> [T] {
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


protocol GifConverter: Converter, ConverterCapability {}

extension GifConverter{
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .gif)
    }
}

class GifConverter_Jpeg: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.jpeg, to:.gif) }

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        return nil
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.imageType == .stillImage
    }
}

class GifConverter_Mov: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.gif) }

    static let supportedPresets = ConverterQualityPreset.originalExcluded

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        if let video = source.asset.asAVAsset, let option = options {
            return convert(video: video, option: option, cancellation: cancellation, progressHandler: progressHandler, async)
        }
        return nil
    }
    
    func convert(video: AVAsset, option: GifConverterDefaultOption, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        guard let videoTrack = video.tracks(withMediaType: .video).first else { return nil }
        
        async.begin()
        
        var gifOptions = option
        
        if gifOptions.frameDelay == 0 {
            gifOptions.frameDelay = Double(1 / videoTrack.nominalFrameRate)
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: video)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.maximumSize = gifOptions.sizeWithAspectRatio()
        
        var times = [NSValue]()
        let tick = CMTime(seconds: gifOptions.frameDelay, preferredTimescale: video.duration.timescale)
        var time = CMTime.zero
        while time <= video.duration {
            times.append(NSValue(time: time))
            time = CMTimeAdd(time, tick)
        }
        
        var imageFiles = [URL]()
        var referenceImage: UIImage?
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, cgImage, actualTime, result, error) in
            autoreleasepool {
                if let cgImage = cgImage {
                    let image = UIImage(cgImage: cgImage).stabilize(with: referenceImage, mode: gifOptions.stabilizationMode)
                    referenceImage = image
                    
                    imageFiles.append(LocalCachedAsset(image: image, targetSize: gifOptions.sizeWithAspectRatio(), imageQuality: CGFloat(gifOptions.gifQuality), contentMode: gifOptions.contentMode).imageFileURL)
                }
                
                if requestedTime == times.last?.timeValue {
                    async.end()
                }
            }
        }
        
        async.waitUntilEnd()
        
        guard let url = UIImageGIFRepresentationURL(with: gifOptions.urlWithDirection(urls: imageFiles), loopCount: gifOptions.loopCount, frameDelay: gifOptions.frameDelay, cancellation: cancellation, progressHandler: progressHandler) else { return nil }
        
        return [PHAssetEditingResultItem(url, .photo)]
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.mediaType == .video && asset.duration < 15
    }
}

class GifConverter_LivePhoto: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.livephoto, to:.gif) }

    static let supportedPresets = ConverterQualityPreset.originalExcluded

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        let extractMovieTask = AsyncSignal()
        if let videoResource = MovConverter_LivePhoto().convert(source: source, cancellation: cancellation, progressHandler: progressHandler, extractMovieTask)?.first, let options = options {
            return GifConverter_Mov().convert(video: AVAsset(url: videoResource.url), option: options, cancellation: cancellation, progressHandler: progressHandler,async)
        }
        return nil
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.imageType == .livePhoto
    }
}

class GifConverter_Timelapse: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.gif) }

    static let supportedPresets = ConverterQualityPreset.originalExcluded

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        let converter = GifConverter_Mov()
        converter.options = options
        return converter.convert(source: source, cancellation: cancellation, progressHandler: progressHandler, async)
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.mediaSubtypes.contains(.videoTimelapse)
    }
}

class GifConverter_Burst: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.burst, to:.gif) }

    static let supportedPresets = ConverterQualityPreset.originalExcluded

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> [PHAssetEditingResultItem]? {
        guard let gifOptions = options else { return nil }
        
        let param = ConverterBurstImageExtractParam(targetSize: gifOptions.sizeWithAspectRatio(), imageQuality: CGFloat(gifOptions.gifQuality), contentMode: gifOptions.contentMode)
        
        guard
            let urls = extractBurstImageURLs(source: source, param: param, stabilizationMode: gifOptions.stabilizationMode, async),
            let url = UIImageGIFRepresentationURL(with: gifOptions.urlWithDirection(urls: urls), loopCount: gifOptions.loopCount, cancellation: cancellation, progressHandler: progressHandler)
        else { return nil }
        return [PHAssetEditingResultItem(url, .photo)]
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.imageType == .burst
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
                data = imageToWrite.pngData()
                fileExtension = "png"
            default:
                data = imageToWrite.jpegData(compressionQuality: imageQuality)
        }
        
        let identifier = asset?.localIdentifierWithoutSplitter ?? UUID().uuidString
        let url = FileURL.temp("\(identifier).\(fileExtension)", group:String(describing: LocalCachedAsset.self)+FileURL.queuePrivateGroup())
        
        try? data?.write(to: url)
        
        self.asset = asset
        self.imageFileURL = url
    }
}
