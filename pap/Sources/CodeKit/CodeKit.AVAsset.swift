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
    static func mergeVideos(_ videos: [AVAsset]) -> AVAsset {
        let composition = AVMutableComposition()
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var insertTime = CMTime.zero
        for video in videos {
            let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: video.duration)
            
            if let videoTrack = video.tracks(withMediaType: .video).first, let _ = try? compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: insertTime) {
                compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
            }
            else {
                compositionVideoTrack?.insertEmptyTimeRange(timeRange)
            }
            
            if let audioTrack = video.tracks(withMediaType: .audio).first, let _ = try? compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: insertTime) {
                compositionAudioTrack?.preferredVolume = audioTrack.preferredVolume
            }
            else {
                compositionAudioTrack?.insertEmptyTimeRange(timeRange)
            }
            
            insertTime = insertTime + video.duration
        }
        
        return composition
    }
}

extension AVAsset {
    func applyTransform(_ transform: CGAffineTransform) -> AVAsset {
        guard
            let videoTrack = tracks(withMediaType: .video).first
            else {
                return self
        }
        
        let audioTrack = tracks(withMediaType: .audio).first
        
        let transform = videoTrack.preferredTransform.concatenating(transform)
        let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
        
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return self
        }
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        try? compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
        
        if let audioTrack = audioTrack {
            do {
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: CMTime.zero)
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
    func applyFilter(_ filter: CIFilter?, cancellation: (() -> Bool)? = nil) -> AVVideoComposition {
        return AVVideoComposition(asset: self) { (request) in
            let image = request.sourceImage.applyFilter(ciFilter: filter)
            if cancellation?() == true {
                request.finish(with: NSError(domain: "AVAsset", code: -500, userInfo: nil)) // User Interrupt
            }
            else {
                request.finish(with: image, context: nil)
            }
        }
    }
}

extension AVAsset {
    func stabilize(with mode: ImageAlignment.StabilizationMode = .translation, cancellation: (() -> Bool)? = nil) -> AVVideoComposition {
        var referenceImage: CIImage?
        
        return AVVideoComposition(asset: self) { (request) in
            let result: CIImage
            if let image = referenceImage {
                result = request.sourceImage.stabilize(with: image, mode: mode)
            }
            else {
                result = request.sourceImage
            }
            referenceImage = request.sourceImage
            
            if cancellation?() == true {
                request.finish(with: NSError(domain: "AVAsset", code: -500, userInfo: nil)) // User Interrupt
            }
            else {
                request.finish(with: result, context: nil)
            }
        }
    }
}

extension AVVideoComposition {
    private static func makeVideoRenderWidth(_ width: CGFloat) -> CGFloat {
        return width.remainder(dividingBy: 4) == 0 ? width : width - width.truncatingRemainder(dividingBy: 4)
    }
    
    static func makeVideoRenderSize(_ size: CGSize) -> CGSize {
        return CGSize(width: makeVideoRenderWidth(size.width), height: makeVideoRenderWidth(size.height))
    }
}
