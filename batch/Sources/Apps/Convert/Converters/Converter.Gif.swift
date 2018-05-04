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
