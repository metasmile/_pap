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
}


protocol GifConverter: Converter {}

extension GifConverter{
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .gif)
    }
}

class GifConverter_Jpeg: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.jpeg, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    static func shouldSelect(source: AppAsset) -> Bool {
        return source.asset.imageType == .stillImage
    }
}

class GifConverter_Mov: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.mov, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    static func shouldSelect(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video
    }
}

class GifConverter_LivePhoto: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    static func shouldSelect(source: AppAsset) -> Bool {
        return source.asset.imageType == .livePhoto
    }
}

class GifConverter_Timelapse: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.timelapse, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    static func shouldSelect(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}

class GifConverter_Burst: OptionableConverterBase<GifConverterDefaultOption>, GifConverter {
    static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.gif) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        let gifOptions = options ?? GifConverterDefaultOption.default
        let param = ConverterBurstImageExtractParam(targetSize: gifOptions.sizeWithAspectRatio(), imageQuality: CGFloat(gifOptions.gifQuality), contentMode: PHImageContentMode(rawValue: gifOptions.contentMode) ?? PHImageContentMode.aspectFit)
        
        let extractTask = AsyncSignal()
        guard let urls = extractBurstImageURLs(source: source, param: param, extractTask) else { return nil }
        let imageFiles: [URL] = {
            if urls.count > 1 {
                switch gifOptions.direction {
                case 1: return urls.reversed()
                case 2: return urls + urls[1...].reversed()[1...]
                default: break
                }
            }
            return []
        }()
        
        return UIImageGIFRepresentationURL(with: imageFiles, loopCount: gifOptions.loopCount, frameDelay: Double(gifOptions.frameDelay) / 1000)
    }

    static func shouldSelect(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
}
