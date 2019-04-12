//
//  CodeKit.AVAsset.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 4..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

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

extension AVAsset {
    func resize(_ size: CGSize, with contentMode: PHImageContentMode = .aspectFit, cancellation: (() -> Bool)? = nil) -> AVVideoComposition {
        let size = AVVideoComposition.makeVideoRenderSize(size)
        
        return AVVideoComposition(asset: self) { (request) in
            var image = request.sourceImage
            if contentMode == .aspectFit {
                image = image.resizeAspectFit(size)
            }
            else {
//                let fillSize = image.extent.size.aspectFill(in: size)
//                image = image.resizeAspectFit(fillSize).cropped(to: AVMakeRect(aspectRatio: fillSize, insideRect: CGRect(origin: CGPoint(x: (fillSize.width - size.width) / 2, y: (fillSize.height - size.height) / 2), size: size)))
            }
            
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
    var renderSize: CGSize {
        return naturalSize.applying(preferredTransform).magnitude
    }
    
    var naturalSize: CGSize {
        return tracks(withMediaType: .video).first?.naturalSize ?? .zero
    }
    
    var preferredTransform: CGAffineTransform {
        return tracks(withMediaType: .video).first?.preferredTransform ?? .identity
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

extension AVAsset {
    // https://chrissung.com/2017/03/11/reverse-video-in-ios/
    func reverse(progress progressHandler: ((Progress) -> Void)? = nil, completion: @escaping (AVAsset?) -> Void) {
        guard let videoTrack = tracks(withMediaType: .video).first else { completion(nil); return }
        
        let numberOfSamplesInGroup = 100
        
        DispatchQueue(label: #file + #function, qos: .utility).async {
            let fps = videoTrack.nominalFrameRate
            
            let assetReader = try? AVAssetReader(asset: self)
            let outputSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            ]
            let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
            output.supportsRandomAccess = true
            
            assetReader?.add(output)
            assetReader?.startReading()
            
            let outputSize = videoTrack.naturalSize
            
            // presentation times
            
            var presentationTimes = [CMTime]()
            
            while let sample = output.copyNextSampleBuffer() {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample)
                presentationTimes.append(presentationTime)
            }
            
            guard let initialTime = presentationTimes.first else { completion(nil); return }
            
            // make reversed groups
            
            struct ReverseGroup {
                var startTime: CMTime
                var endTime: CMTime
                var timeStartIndex: Int
                var timeEndIndex: Int
                var frameStartIndex: Int
                var frameEndIndex: Int
                
                var duration: CMTime {
                    return CMTimeSubtract(endTime, startTime)
                }
            }
            
            let numberOfFrames = presentationTimes.count
            let estimatedNumberOfGroups = Int(ceil(Float(numberOfFrames) / Float(numberOfSamplesInGroup)))
            
            var reverseGroups = [ReverseGroup]()
            
            var startTime: CMTime = initialTime
            var timeStartIndex: Int = 0
            var frameStartIndex: Int = numberOfFrames - 1
            
            for (i, presentationTime) in presentationTimes.enumerated() {
                if i > 0, i % numberOfSamplesInGroup == 0 {
                    let reversedIndex = numberOfFrames - 1 - i
                    
                    let group = ReverseGroup(startTime: startTime, endTime: presentationTime, timeStartIndex: timeStartIndex, timeEndIndex: i, frameStartIndex: frameStartIndex, frameEndIndex: reversedIndex)
                    reverseGroups.append(group)
                    
                    startTime = presentationTime
                    timeStartIndex = i
                    frameStartIndex = reversedIndex
                }
            }
            
            if reverseGroups.count < estimatedNumberOfGroups || presentationTimes.count % numberOfSamplesInGroup > 0, let presentationTime = presentationTimes[safe: numberOfFrames - 1] {
                let group = ReverseGroup(startTime: startTime, endTime: presentationTime, timeStartIndex: timeStartIndex, timeEndIndex: numberOfFrames - 1, frameStartIndex: frameStartIndex, frameEndIndex: 0)
                reverseGroups.append(group)
            }
            
            // write reversed video
            
            let url = FileURL.temp("\(UUID().uuidString)_reversed", UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            let assetWriter = try? AVAssetWriter(url: url, fileType: AVFileType.mov)
            let inputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(outputSize.width),
                AVVideoHeightKey: Int(outputSize.height)
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: inputSettings)
            input.expectsMediaDataInRealTime = false
            input.transform = videoTrack.preferredTransform
            
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
            
            assetWriter?.add(input)
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: initialTime)
            
            var frameCount = 0
            let fpsInt = Int(fps + 0.5)
            
            let progress = Progress(totalUnitCount: Int64(reverseGroups.count))
            
            for group in reverseGroups.reversed() {
                let timeRange = CMTimeRange(start: group.startTime, duration: group.duration)
                output.reset(forReadingTimeRanges: [NSValue(timeRange: timeRange)])
                
                var samples = [CMSampleBuffer]()
                while let sample = output.copyNextSampleBuffer() {
                    samples.append(sample)
                }
                
                let numberOfSamples = samples.count
                
                for i in 0..<numberOfSamples {
                    let childProgress = Progress(totalUnitCount: Int64(numberOfSamples))
                    progress.addChild(childProgress, withPendingUnitCount: 1)
                    
                    let reversedIndex = numberOfSamples - 1 - i
                    
                    guard
                        let time = presentationTimes[safe: frameCount],
                        let sample = samples[safe: reversedIndex],
                        let pixelBuffer = CMSampleBufferGetImageBuffer(sample)
                    else {
                        frameCount += 1
                        childProgress.completedUnitCount += 1
                        progressHandler?(progress)
                        continue
                    }
                    
                    var appended = false
                    var attempToAppendCount = 0
                    while !appended && attempToAppendCount < fpsInt {
                        if adaptor.assetWriterInput.isReadyForMoreMediaData {
                            appended = adaptor.append(pixelBuffer, withPresentationTime: time)
                        }
                        else {
                            Thread.sleep(forTimeInterval: 0.05)
                        }
                        attempToAppendCount += 1
                    }
                    
                    frameCount += 1
                    childProgress.completedUnitCount += 1
                    progressHandler?(progress)
                }
            }
            
            input.markAsFinished()
            
            assetWriter?.finishWriting {
                completion(AVAsset(url: url))
            }
        }
    }
}
