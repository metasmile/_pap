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
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
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
