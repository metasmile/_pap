//
//  TimeLapseBuilder30.swift
//
//  Created by Adam Jensen on 11/18/16.

//
//  TimeLapseBuilder30.swift
//
//  Created by Adam Jensen on 11/18/16.
//  Newly Written by metasmile (github.com/metasmile) on 9/12/16.

//  NOTE: This implementation is written in Swift 3.0.

import AVFoundation
import UIKit

let kErrorDomain = "TimeLapseBuilder"
let kFailedToStartAssetWriterError = 0
let kFailedToAppendPixelBufferError = 1

public final class TimelapsVideoBuilder: NSObject {
    private var videoWriter: AVAssetWriter?

    var fps: Int32 = 30
    var fpsEachImages = [String: Int32]()
    
    var inputSize: CGSize = .zero
    var outputSize: CGSize = .zero
    var destinationFilePath: String?
    var pixelFormatType:OSType = kCVPixelFormatType_32ARGB

    let imagePaths: [String]
    init(imagePaths: [String]) {
        self.imagePaths = imagePaths
    }

    func initProperties(){
        if self.inputSize.equalTo(.zero){
            self.inputSize = UIImage(contentsOfFile: imagePaths.first! as String)!.size
        }
        
        if self.outputSize == .zero {
            self.outputSize = self.inputSize
        }
    }

    func build(_ progress: @escaping ((Progress) -> Void), success: @escaping ((URL) -> Void), failure: @escaping ((NSError) -> Void)) {
        self.initProperties()

        let inputSize = self.inputSize
        let outputSize = self.outputSize
        
        var error: NSError?

        let documentsPath = self.destinationFilePath ?? (NSTemporaryDirectory() as NSString).appendingPathComponent("TimeLapseVideo.mov")
        let videoOutputURL = URL(fileURLWithPath: documentsPath)

        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {}

        do {
            try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mov)
        } catch let writerError as NSError {
            error = writerError
            videoWriter = nil
        }

        if let videoWriter = videoWriter {
            let videoSettings: [String : Any] = [
                AVVideoCodecKey  : AVVideoCodecType.h264,
                AVVideoWidthKey  : outputSize.width,
                AVVideoHeightKey : outputSize.height,
                //        AVVideoCompressionPropertiesKey : [
                //          AVVideoAverageBitRateKey : NSInteger(1000000),
                //          AVVideoMaxKeyFrameIntervalKey : NSInteger(16),
                //          AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel
                //        ]
            ]

            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)

            let sourceBufferAttributes = [
                (kCVPixelBufferPixelFormatTypeKey as String): Int(self.pixelFormatType),
                (kCVPixelBufferWidthKey as String): Float(inputSize.width),
                (kCVPixelBufferHeightKey as String): Float(inputSize.height)] as [String : Any]

            let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: videoWriterInput,
                    sourcePixelBufferAttributes: sourceBufferAttributes
            )

            assert(videoWriter.canAdd(videoWriterInput))
            videoWriter.add(videoWriterInput)

            if videoWriter.startWriting() {
                videoWriter.startSession(atSourceTime: kCMTimeZero)
                assert(pixelBufferAdaptor.pixelBufferPool != nil)

                let media_queue = DispatchQueue(label: "mediaInputQueue")

                videoWriterInput.requestMediaDataWhenReady(on: media_queue) {
                    let currentProgress = Progress(totalUnitCount: Int64(self.imagePaths.count))

                    var frameCount: Int64 = 0
                    var remainingPhotoURLs = [String](self.imagePaths)

                    while videoWriterInput.isReadyForMoreMediaData && !remainingPhotoURLs.isEmpty {
                        let nextPhotoURL = remainingPhotoURLs.remove(at: 0)
                        
                        let fps: Int32 = self.fpsEachImages[nextPhotoURL] ?? self.fps
                        let frameDuration = CMTimeMake(1, fps)
                        let lastFrameTime = CMTimeMake(frameCount, fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)

                        if !self.appendPixelBufferForImageAtURL(nextPhotoURL, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                            error = NSError(
                                    domain: kErrorDomain,
                                    code: kFailedToAppendPixelBufferError,
                                    userInfo: ["description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer"]
                            )

                            break
                        }

                        frameCount += 1

                        currentProgress.completedUnitCount = frameCount
                        progress(currentProgress)
                    }

                    videoWriterInput.markAsFinished()
                    videoWriter.finishWriting {
                        if let error = error {
                            failure(error)
                        } else {
                            print("videoWriter.finishWriting ", videoOutputURL)
                            success(videoOutputURL)
                        }

                        self.videoWriter = nil
                    }
                }
            } else {
                error = NSError(
                        domain: kErrorDomain,
                        code: kFailedToStartAssetWriterError,
                        userInfo: ["description": "AVAssetWriter failed to start writing"]
                )
            }
        }

        if let error = error {
            failure(error)
        }
    }

    func appendPixelBufferForImageAtURL(_ url: String, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        return autoreleasepool {
            var appendSucceeded = false

            let url = URL(fileURLWithPath: url)

            if let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData),
               let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                        kCFAllocatorDefault,
                        pixelBufferPool,
                        pixelBufferPointer
                )

                if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)

                    appendSucceeded = pixelBufferAdaptor.append(
                            pixelBuffer,
                            withPresentationTime: presentationTime
                    )

                    pixelBufferPointer.deinitialize(count: 1)
                } else {
                    print("error: Failed to allocate pixel buffer from pool")
                }

                pixelBufferPointer.deallocate()
            }

            return appendSucceeded
        }
    }

    func fillPixelBufferFromImage(_ image: UIImage, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
                data: pixelData,
                width: Int(image.size.width),
                height: Int(image.size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: rgbColorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
}
