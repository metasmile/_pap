//
//  AssetIO.LivePhotoResource.Video.swift
//  Live Photos
//
//  Originally Created by genadyo (github.com/genadyo).
//  Newly Written by metasmile (github.com/metasmile) on 9/12/16.
//

import Foundation
import AVFoundation

public class LivePhotoVideoResourceWriter: NSObject {
    private let kKeyContentIdentifier = "com.apple.quicktime.content.identifier"
    private let kKeyStillImageTime = "com.apple.quicktime.still-image-time"
    private let kKeySpaceQuickTimeMetadata = "mdta"
    public var path: String

    public lazy var writeQueue = DispatchQueue(label: "com.stells.LivePhotoMovieResourceWriter.write")

    static let dummyTimeRange = CMTimeRangeMake(CMTimeMake(0, 1000), CMTimeMake(200, 3000))

    private lazy var asset: AVURLAsset = {
        return AVURLAsset(url: URL(fileURLWithPath: self.path))
    }()

    public init(path: String) {
        self.path = path
    }

    func readAssetIdentifier() -> String? {
        for item in metadata() {
            if item.key as? String == kKeyContentIdentifier && item.keySpace == AVMetadataKeySpace.quickTimeMetadata {
                return item.value as? String
            }
        }
        return nil
    }

    func readStillImageTime() -> NSNumber? {
        if let track = track(mediaType: .metadata) {
            if let (reader, output) = try? self.reader(track: track, settings: nil) {
                reader.startReading()

                while true {
                    guard let buffer = output.copyNextSampleBuffer() else {
                        return nil
                    }
                    if CMSampleBufferGetNumSamples(buffer) != 0 {
                        let group = AVTimedMetadataGroup(sampleBuffer: buffer)
                        for item in group?.items ?? [] {
                            if item.key as? String == kKeyStillImageTime && item.keySpace == AVMetadataKeySpace.quickTimeMetadata {
                                return item.numberValue
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    public func write(destPath: String, assetIdentifier: String) {
        do {
            // --------------------------------------------------
            // reader for source video
            // --------------------------------------------------
            guard let track = self.track(mediaType: .video) else {
                print("not found video track")
                return
            }
            let (reader, output) = try self.reader(track: track,
                    settings: [kCVPixelBufferPixelFormatTypeKey as String:
                    NSNumber(value: kCVPixelFormatType_32BGRA)])

            // --------------------------------------------------
            // writer for mov
            // --------------------------------------------------
            let writer = try AVAssetWriter(outputURL: URL(fileURLWithPath: destPath), fileType: .mov)
            writer.metadata = [metadataFor(assetIdentifier: assetIdentifier)]

            // video track
            let input = AVAssetWriterInput(mediaType: AVMediaType.video,
                    outputSettings: videoSettings(size: track.naturalSize))
            input.expectsMediaDataInRealTime = true
            input.transform = track.preferredTransform
            writer.add(input)

            // metadata track
            let adapter = metadataAdapter()
            writer.add(adapter.assetWriterInput)

            // --------------------------------------------------
            // creating video
            // --------------------------------------------------
            writer.startWriting()
            reader.startReading()
            writer.startSession(atSourceTime: kCMTimeZero)

            // write metadata track
            adapter.append(
                    AVTimedMetadataGroup(items: [metadataForStillImageTime()], timeRange: type(of: self).dummyTimeRange)
            )

            // write video track

            let semaphore_write = DispatchSemaphore(value: 0)
            input.requestMediaDataWhenReady(on: self.writeQueue) {
                while (input.isReadyForMoreMediaData) {
                    if reader.status == .reading {
                        if let buffer = output.copyNextSampleBuffer() {
                            if !input.append(buffer) {
                                print("cannot write: \(String(describing: writer.error))")

                                reader.cancelReading()
                            }
                            semaphore_write.signal()
                        }
                    } else {
                        input.markAsFinished()
                        writer.finishWriting() {
                            semaphore_write.signal()

                            if let e = writer.error {
                                print("cannot write: \(e)")
                            } else {
                                print("finish writing.")
                            }
                        }

                    }
                }
            }
            while writer.status == .writing {
                semaphore_write.wait()
            }

            if let e = writer.error {
                print("cannot write: \(e)")
            }
        } catch {
            print("error")
        }
    }

    private func metadata() -> [AVMetadataItem] {
        return asset.metadata(forFormat: AVMetadataFormat.quickTimeMetadata)
    }

    private func track(mediaType: AVMediaType) -> AVAssetTrack? {
        return asset.tracks(withMediaType: mediaType).first
    }

    private func reader(track: AVAssetTrack, settings: [String: AnyObject]?) throws -> (AVAssetReader, AVAssetReaderOutput) {
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        let reader = try AVAssetReader(asset: asset)
        reader.add(output)
        return (reader, output)
    }

    private func metadataAdapter() -> AVAssetWriterInputMetadataAdaptor {
        let spec = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String: "\(kKeySpaceQuickTimeMetadata)/\(kKeyStillImageTime)",

            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String:
            "com.apple.metadata.datatype.int8"
        ]

        var desc: CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, [spec] as CFArray, &desc)

        let input = AVAssetWriterInput(mediaType: AVMediaType.metadata,
                outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }

    private func videoSettings(size: CGSize) -> [String: Any] {
        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
    }

    private func metadataFor(assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyContentIdentifier as NSCopying & NSObjectProtocol
        item.keySpace = AVMetadataKeySpace(rawValue: kKeySpaceQuickTimeMetadata)
        item.value = assetIdentifier as NSCopying & NSObjectProtocol
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }

    private func metadataForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = kKeyStillImageTime as NSCopying & NSObjectProtocol
        item.keySpace = AVMetadataKeySpace(rawValue: kKeySpaceQuickTimeMetadata)
        item.value = 0 as NSCopying & NSObjectProtocol
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
}
