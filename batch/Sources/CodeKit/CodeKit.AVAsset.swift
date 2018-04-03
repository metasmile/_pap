//
//  CodeKit.AVAsset.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 4..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation

extension AVAsset {
    func applyTransform(_ transform: CGAffineTransform) -> AVAsset {
        guard
            let videoTrack = tracks(withMediaType: .video).first
            else {
                return self
        }
        
        let audioTrack = tracks(withMediaType: .audio).first
        
        let transform = videoTrack.preferredTransform.concatenating(transform)
        let timeRange = CMTimeRangeMake(kCMTimeZero, duration)
        
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return self
        }
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        try? compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: kCMTimeZero)
        
        if let audioTrack = audioTrack {
            do {
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: kCMTimeZero)
            } catch {
                if let track = compositionAudioTrack {
                    composition.removeTrack(track)
                }
            }
        }
        
        compositionVideoTrack.preferredTransform = transform
        
        return composition
    }
}

extension AVAsset {
    func applyFilter(_ filter: CIFilter?) -> AVVideoComposition {
        return AVVideoComposition(asset: self) { (request) in
            let image = request.sourceImage.applyFilter(ciFilter: filter)
            request.finish(with: image, context: nil)
        }
    }
}
