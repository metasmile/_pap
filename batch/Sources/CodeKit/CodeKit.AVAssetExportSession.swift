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
    static func `init`(asset: AVAsset, videoComposition: AVVideoComposition?, presetName: String = AVAssetExportPresetPassthrough, outputFileType: AVFileType = AVFileType.mov, outputURL: URL, progressHandler: ((Float) -> Void)? = nil, completionHandler: @escaping (Bool) -> Void) -> AVAssetExportSession? {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            return nil
        }

        let exportingVideo = DispatchGroup()
        exportingVideo.enter()
        
        try? FileManager.default.removeItem(at: outputURL)

        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = false
        exportSession.exportAsynchronously {
            exportingVideo.leave()

            switch exportSession.status {
            case .completed:
                completionHandler(true)
            case .failed, .cancelled:
                completionHandler(false)
            default:
                break
            }
        }

        if let progress = progressHandler {
            DispatchQueue.global().async {
                while exportSession.status == .waiting || exportSession.status == .exporting {
                    progress(exportSession.progress)
                    _ = exportingVideo.wait(timeout: DispatchTime.now() + 0.5)
                }
            }
        }

        return exportSession
    }
}
