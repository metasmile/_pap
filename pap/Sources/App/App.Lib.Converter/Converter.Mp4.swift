//
// Created by BLACKGENE on 08/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO
import MobileCoreServices

struct MP4ConverterOption {
    var avAssetPreset:String = AVAssetExportPresetPassthrough

    static func optionBy(_ quality: ConverterQualityPreset, with asset: PHAsset) -> MP4ConverterOption {
        switch quality{
        case .low:
            return MP4ConverterOption(avAssetPreset: AVAssetExportPreset960x540)
        case .medium:
            return MP4ConverterOption(avAssetPreset: AVAssetExportPreset1280x720)
        case .high:
            return MP4ConverterOption(avAssetPreset: AVAssetExportPreset1920x1080)
        case .original:
            return MP4ConverterOption()
        }
    }
}

protocol MP4Converter: Converter, ConverterCapability {}

extension MP4Converter {
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .mp4)
    }
}

class MP4Converter_Mov: OptionableConverterBase<MP4ConverterOption>, MP4Converter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.mp4) }

    static let supportedPresets = ConverterQualityPreset.all
    
    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> Any? {
        guard let video = source.asset.asAVAsset else { return nil }

        let url = FileURL.temp(source.asset.localIdentifierWithoutSplitter, UTI.mpeg4, group: FileURL.fileAndQueuePrivateGroup())
        async.begin()

        let preset = (self.options ?? MP4ConverterOption()).avAssetPreset
        AVAssetExportSession.export(asset: video, presetName:preset, outputFileType: .mp4, outputURL: url, shouldOptimizeForNetworkUse: true, progressHandler: progressHandler) { (success) in
            async.end()
        }

        async.waitUntilEnd()
        return url
    }
    
    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video && source.asset.duration < 15 && source.asset.uniformTypeIdentifier != (kUTTypeMPEG4 as String)
    }
}

class MP4Converter_Timelapse: OptionableConverterBase<MP4ConverterOption>, MP4Converter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.mp4) }

    static let supportedPresets = ConverterQualityPreset.all

    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> Any? {
        let converter = MP4Converter_Mov()
        converter.options = self.options
        return converter.convert(source: source, cancellation: cancellation, progressHandler: progressHandler, async)
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}
