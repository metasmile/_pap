//
// Created by BLACKGENE on 08/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO
import MobileCoreServices

public struct MP4ConverterOption{

}

protocol MP4Converter: Converter, ConverterCapability {}

extension MP4Converter {
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .mp4)
    }
}

class MP4Converter_Mov: OptionableConverterBase<MP4ConverterOption>, MP4Converter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.mp4) }

    static let supportedPresets = ConverterQualityPreset.originalOnly
    
    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {
        guard let video = source.asset.asAVAsset else { return nil }

        let url = FileURL.temp(source.asset.localIdentifierWithoutSplitter, UTI.mpeg4, group: FileURL.fileAndQueuePrivateGroup())
        async.begin()
        AVAssetExportSession.export(asset: video, presetName:AVAssetExportPreset1920x1080, outputFileType: .mp4, outputURL: url, shouldOptimizeForNetworkUse: true) { (success) in
            async.end()
        }

        async.waitUntilEnd()
        return PHAssetResourceFinalizingOutput(resources: [(resourceType: .video, url: url)])
    }
    
    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video && source.asset.uniformTypeIdentifier != (kUTTypeMPEG4 as String)
    }
    
    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumUserLibrary
    }
    
    static var performMediaType: PHAssetMediaType? {
        return .video
    }
}

struct MP4Converter_Timelapse: MP4Converter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.mp4) }

    static let supportedPresets = ConverterQualityPreset.all

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {
        let converter = MP4Converter_Mov()
        return converter.convert(source: source, async)
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.videoTimelapse)
    }

    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumUserLibrary
    }

    static var performMediaType: PHAssetMediaType? {
        return .video
    }
}
