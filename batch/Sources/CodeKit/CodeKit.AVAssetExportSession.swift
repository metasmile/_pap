//
//  CodeKit.AVAssetExportSession.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 23..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation

extension AVAssetExportSession {

    @discardableResult
    static func export(asset: AVAsset, videoComposition: AVVideoComposition? = nil
            , presetName: String = AVAssetExportPresetPassthrough
            , outputFileType: AVFileType = AVFileType.mov
            , outputURL: URL
            , shouldOptimizeForNetworkUse: Bool = false
            , progressHandler: PHAssetEditableProgressHandler? = nil
            , completionHandler: @escaping (Bool) -> Void) -> AVAssetExportSession? {

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            return nil
        }
        
        let async = AsyncSignal()
        async.begin()

        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = shouldOptimizeForNetworkUse
        exportSession.exportAsynchronously {
            async.end()

            switch exportSession.status {
            case .completed:
                completionHandler(true)
            case .failed, .cancelled:
                completionHandler(false)
            default:
                break
            }
        }
        
        let exportProgress = Progress(totalUnitCount: 100)

        if let progress = progressHandler {
            DispatchQueue.global().async {
                while exportSession.status == .waiting || exportSession.status == .exporting {
                    exportProgress.completedUnitCount = Int64(exportSession.progress * 100)
                    progress(exportProgress)
                    _ = async.waitUntilEnd(timeout: DispatchTime.now() + 0.5)
                }
            }
        }

        return exportSession
    }
}
