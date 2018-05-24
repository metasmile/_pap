//
// Created by BLACKGENE on 08/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO
import MobileCoreServices

protocol MP4Converter: Converter {}

extension MP4Converter {
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .mp4)
    }
}

struct MP4Converter_Mov: MP4Converter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov, to:.mp4) }
    
    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        guard let video = source.asset.asAVAsset else { return nil }

        let url = FileURL.temp(source.asset.localIdentifierWithoutSplitter, UTI.mpeg4, group: FileURL.fileAndQueuePrivateGroup())
        async.begin()
        AVAssetExportSession.init(asset: video, outputFileType: .mp4, outputURL: url, shouldOptimizeForNetworkUse: true) { (success) in
            async.end()
        }
        async.waitUntilEnd()
        return url
    }
    
    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaType == .video && source.asset.uniformTypeIdentifier != (kUTTypeMPEG4 as String)
    }
}

struct MP4Converter_Timelapse: MP4Converter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.mov_timelapse, to:.mp4) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        let converter = MP4Converter_Mov()
        return converter.convert(source: source, async)
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}
