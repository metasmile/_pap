//
//  TransformApp.Contents.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 8. 23..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

public class TransformEditItem: TaskConfigable {
    private (set) var transformItems = [TransformItem]()

    var hasChanges: Bool {
        return !transformItems.isEmpty //!transform.isIdentity
    }

    func addTransformItem(_ item: TransformItem) {
        transformItems.append(item)
    }

    func merge(_ editItem: TransformEditItem) {
        transformItems.append(contentsOf: editItem.transformItems)
    }

    func resetTransforms() {
        transformItems.removeAll()
    }

    var transform: CGAffineTransform {
        var t = CGAffineTransform.identity
        for transformItem in transformItems {
            t = t.concatenating(transformItem.transform)
        }
        return t
    }

    var transform3d: CATransform3D {
        var t = CATransform3DIdentity
        t.m34 = -1 / kEditItemPreviewWidth

        for transformItem in transformItems {
            t = CATransform3DConcat(t, transformItem.transform3d)
        }
        return t
    }
}

class TransformItem: NSObject {
    var transform: CGAffineTransform {
        return .identity
    }

    var transform3d: CATransform3D {
        return CATransform3DIdentity
    }
}

class RotationTransformItem: TransformItem {
    var angle: CGFloat = 0

    override var transform: CGAffineTransform {
        return CGAffineTransform(rotationAngle: angle)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(angle, 0, 0, 1)
    }

    init(degrees: CGFloat) {
        super.init()

        self.angle = degrees.degreesToRadians
    }

    init(radians: CGFloat) {
        super.init()

        self.angle = radians
    }
}

class VerticalFlipTransformItem: TransformItem {
    override var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: 1, y: -1)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 1, 0, 0)
    }
}

class HorizontalFlipTransformItem: TransformItem {
    override var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: -1, y: 1)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 0, 1, 0)
    }
}


class TaskQueue: NSObject {
    private var taskItems = [DispatchWorkItem]()
    private let taskQueue = DispatchQueue(label: "com.stells.batch.dispatchQueue.taskQueue")
    private var finishBlock: (() -> Void)?

    var remainTasks: Int {
        return taskItems.count
    }

    func addTask(_ task: @escaping () -> Void) {
        taskItems.append(DispatchWorkItem(block: task))
    }

    func performNext() {
        if !taskItems.isEmpty {
            taskQueue.async(execute: taskItems.removeFirst())
        }
        else {
            finishBlock?()
        }
    }

    var isProcessing: Bool {
        return !taskItems.isEmpty
    }

    func cancel() {
        for taskItem in taskItems {
            taskItem.cancel()
        }
        taskItems.removeAll()

        finishBlock = nil
    }

    func setFinishBlock(_ block: (() -> Void)?) {
        finishBlock = block
    }
}

public class TransformAppEditItem: NSObject, TaskParamable {
    fileprivate var imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    var asset: PHAsset?
    var editItem = TransformEditItem()
}

extension TransformAppEditItem {
    func runEditing(_ progressHandler: ((Float) -> Void)? = nil, _ completionHandler: @escaping (PHAsset?, PHContentEditingOutput?) -> Void) {
        if asset?.mediaType == .image {
            if asset!.mediaSubtypes.contains(.photoLive) {
                self.editLivePhoto(completionHandler)
            }
            else {
                loadImage(progressHandler) { [weak self] (image) in
                    self?.editImage(image, completion: completionHandler)
                }
            }
        }
        else if asset?.mediaType == .video {
            loadVideo(progressHandler) { [weak self] (video, audioMix) in
                self?.editVideo(video, audioMix: audioMix, completion: completionHandler)
            }
        }
    }

    func cancelEditing() {
        PHImageManager.default().cancelImageRequest(imageRequestID)
        imageRequestID = PHInvalidImageRequestID
    }

    fileprivate func loadImage(_ progressHandler: ((Float) -> Void)? = nil, _ completionHandler: @escaping ((UIImage?) -> Void)) {
        guard let asset = self.asset else {
            completionHandler(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        options.resizeMode = .none
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            progressHandler?(Float(progress))
        }

        imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: options) { (image, info) in
            guard let image = image else {
                completionHandler(nil)
                return
            }

            if let degraded = info?[PHImageResultIsDegradedKey] as? NSNumber, !degraded.boolValue {
                completionHandler(image)
            }
        }
    }

    fileprivate func editImage(_ image: UIImage?, completion completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let image = image?.applyTransform(editItem.transform),
            let asset = self.asset
        else {
            completionHandler(nil, nil)
            return
        }

        asset.requestContentEditingInput(with: nil) { (input, info) in
            guard let input = input else {
                completionHandler(nil, nil)
                return
            }

            guard let dataInfo = "Edited".data(using: .utf8) else {
                completionHandler(nil, nil)
                return
            }

            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: input)
            contentEditingOutput.adjustmentData = PHAdjustmentData(formatIdentifier: Bundle.main.bundleIdentifier ?? "", formatVersion: "1.0", data: dataInfo)

            // renderedContentURL supports only JPEG and MOV ...
            // so... always export JPEG
            let outputData = UIImageJPEGRepresentation(image, 1)
//            var outputData: Data?
//            switch input.uniformTypeIdentifier {
//            case String(kUTTypePNG)?:
//                outputData = UIImagePNGRepresentation(image)
//            default:
//                outputData = UIImageJPEGRepresentation(image, 1)
//            }

            guard (try? outputData?.write(to: contentEditingOutput.renderedContentURL, options: .atomic)) != nil else {
                completionHandler(nil, nil)
                return
            }

            completionHandler(asset, contentEditingOutput)
        }
    }
}

extension TransformAppEditItem {
    fileprivate func loadLivePhoto(_ progressHandler: ((Float) -> Void)? = nil, _ completionHandler: @escaping ((PHLivePhoto?) -> Void)) {
        guard let asset = self.asset else {
            completionHandler(nil)
            return
        }

        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            progressHandler?(Float(progress))
        }

        imageRequestID = PHImageManager.default().requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options, resultHandler: { (livePhoto, info) in
            completionHandler(livePhoto)
        })
    }

    fileprivate func editLivePhoto(_ completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let asset = self.asset
            else {
                completionHandler(nil, nil)
                return
        }

        asset.requestContentEditingInput(with: nil) { (input, info) in
            guard let input = input else {
                completionHandler(nil, nil)
                return
            }

            guard let dataInfo = "Edited".data(using: .utf8) else {
                completionHandler(nil, nil)
                return
            }

            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: input)
            contentEditingOutput.adjustmentData = PHAdjustmentData(formatIdentifier: Bundle.main.bundleIdentifier ?? "", formatVersion: "1.0", data: dataInfo)

            let editingContext = PHLivePhotoEditingContext(livePhotoEditingInput: input)
            editingContext?.frameProcessor = { frame, error in
                return frame.image.transformed(by: self.editItem.transform)
            }

            editingContext?.saveLivePhoto(to: contentEditingOutput, options: nil, completionHandler: { (success, error) in
                guard success else {
                    completionHandler(nil, nil)
                    return
                }
                completionHandler(asset, contentEditingOutput)
            })
        }
    }

    fileprivate func editLivePhoto(_ livePhoto: PHLivePhoto?, completion completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let livePhoto = livePhoto
        else {
            completionHandler(nil, nil)
            return
        }

        let resources = PHAssetResource.assetResources(for: livePhoto)

        guard
            let videoResource = resources.first(where: { $0.type == PHAssetResourceType.pairedVideo }),
            let photoResource = resources.first(where: { $0.type == PHAssetResourceType.photo })
        else {
            completionHandler(nil, nil)
            return
        }

        var pairedVideo: AVAsset?
        var pairedPhoto: UIImage?
        let retrievePairedResourcesHandler = { [weak self] in
            guard
                let editItem = self?.editItem,
                let video = pairedVideo?.applyTransform(editItem.transform),
                let photo = pairedPhoto?.applyTransform(editItem.transform)
            else { return }


        }

        var videoData = Data()
        var photoData = Data()

        PHAssetResourceManager.default().requestData(for: videoResource, options: nil, dataReceivedHandler: { (data) in
            videoData.append(data)
        }) { (error) in
            guard error == nil else {
                completionHandler(nil, nil)
                return
            }

            let pairedVideoFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("pairedVideo.mov")
            try? videoData.write(to: pairedVideoFileURL, options: Data.WritingOptions.atomicWrite)
            pairedVideo = AVAsset(url: pairedVideoFileURL)
            retrievePairedResourcesHandler()
        }

        PHAssetResourceManager.default().requestData(for: photoResource, options: nil, dataReceivedHandler: { (data) in
            photoData.append(data)
        }) { (error) in
            guard error == nil else {
                completionHandler(nil, nil)
                return
            }

            pairedPhoto = UIImage(data: photoData)
            retrievePairedResourcesHandler()
        }
    }
}

extension TransformAppEditItem {
    fileprivate func loadVideo(_ progressHandler: ((Float) -> Void)? = nil, _ completionHandler: @escaping ((AVAsset?, AVAudioMix?) -> Void)) {
        guard let asset = self.asset else {
            completionHandler(nil, nil)
            return
        }

        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            progressHandler?(Float(progress))
        }

        imageRequestID = PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (video, audioMix, info) in
            completionHandler(video, audioMix)
        }
    }

    fileprivate func editVideo(_ video: AVAsset?, audioMix: AVAudioMix?, completion completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let video = video?.applyTransform(editItem.transform),
            let videoTrack = video.tracks(withMediaType: .video).first,
            let asset = asset
        else {
            completionHandler(nil, nil)
            return
        }

        asset.requestContentEditingInput(with: nil) { (input, info) in
            guard let input = input else {
                completionHandler(nil, nil)
                return
            }

            guard let dataInfo = "Edited".data(using: .utf8) else {
                completionHandler(nil, nil)
                return
            }

            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: input)
            contentEditingOutput.adjustmentData = PHAdjustmentData(formatIdentifier: Bundle.main.bundleIdentifier ?? "", formatVersion: "1.0", data: dataInfo)

            let videoComposition = AVMutableVideoComposition(propertiesOf: video)
            videoComposition.renderSize = videoTrack.naturalSize.applying(self.editItem.transform).magnitude
            videoComposition.frameDuration = CMTimeMake(1, videoTrack.naturalTimeScale)

            let exportSession = AVAssetExportSession(asset: video, presetName: AVAssetExportPresetPassthrough)
            exportSession?.outputFileType = AVFileType.mov
            exportSession?.outputURL = contentEditingOutput.renderedContentURL
            exportSession?.videoComposition = videoComposition
            exportSession?.shouldOptimizeForNetworkUse = false
            exportSession?.exportAsynchronously {
                guard let status = exportSession?.status else { return }
                switch status {
                case .completed:
                    completionHandler(asset, contentEditingOutput)
                case .failed, .cancelled:
                    completionHandler(nil, nil)
                default:
                    break
                }
            }
        }
    }
}

let kEditItemPreviewWidth: CGFloat = UIScreen.main.bounds.width * 0.9


private extension AVAsset {
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

//https://gist.github.com/schickling/b5d86cb070130f80bb40
private extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        var transform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi/2)
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat.pi/2)
            break
        case .up, .upMirrored:
            break
        }

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        }

        var rotatedSize = size
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            rotatedSize = CGSize(width: size.height, height: size.width)
            break
        default:
            break
        }

        return UIGraphicsImageRenderer(size: rotatedSize, format: imageRendererFormat).image { (ctx) in
            guard let cgImage = self.cgImage else { return }
            ctx.cgContext.concatenate(transform)
            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: rotatedSize))
        }
    }
}


/*
 under construction
*/


class BatchRequest: NSObject {
    func cancel() {

    }
}

class BatchEditRequest: BatchRequest {
    fileprivate var batchEditItem: TransformAppEditItem?

    init(_ batchEditItem: TransformAppEditItem) {
        super.init()

        self.batchEditItem = batchEditItem
    }

    func perform(_ progress: ((Float) -> Void)? = nil, _ completion: ((TransformAppTaskResult?) -> Void)? = nil) {
        guard let batchEditItem = batchEditItem else {
            completion?(nil)
            return
        }

        batchEditItem.runEditing(progress) { (asset, contentEditingOutput) in
            var result: TransformAppTaskResult?
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = TransformAppTaskResult(asset: asset, contentEditingOutput: contentEditingOutput)
            }
            completion?(result)
        }
    }

    override func cancel() {
        super.cancel()

        batchEditItem?.cancelEditing()
    }
}

class BatchEditSequenceRequest: BatchRequest {
    fileprivate var batchQueue = TaskQueue()
    fileprivate var requests: [BatchEditRequest]?

    func perform(_ requests: [BatchEditRequest], _ progressHandler: ((Float, Int?) -> Void)? = nil, _ completionHandler: (([TransformAppTaskResult]) -> Void)? = nil) {
        self.requests = requests

        let numberOfRequests = requests.count
        var results = [TransformAppTaskResult]()

        let progressPerRequest = 1 / Float(numberOfRequests)

        for (idx, request) in requests.enumerated() {
            autoreleasepool {
                self.batchQueue.addTask({
                    request.perform({ progress in

                        progressHandler?(Float(idx) / Float(numberOfRequests) + progressPerRequest * progress, nil)

                    }) { result in
                        if let result = result {
                            results.append(result)
                        }
                        progressHandler?(Float(idx + 1) / Float(numberOfRequests), idx)

                        self.batchQueue.performNext()
                    }
                })
            }
        }

        batchQueue.setFinishBlock {
            completionHandler?(results)
            self.requests = nil
        }
        batchQueue.performNext()
    }

    override func cancel() {
        batchQueue.cancel()

        guard let requests = self.requests else { return }
        for request in requests {
            request.cancel()
        }
    }
}
