//
//  BatchItem.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 8. 23..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class TaskQueue: NSObject {
    private var taskItems = [DispatchWorkItem]()
    private let taskQueue = DispatchQueue(label: "com.stells.batch.dispatchQueue.taskQueue")
    private var finishBlock: (() -> Void)?
    
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

class BatchEditItem: NSObject {
    var asset: PHAsset?
    var editItem = EditItem()
    
    func runEditing(_ completion: @escaping (PHAsset?, PHContentEditingOutput?) -> Void) {
        if asset?.mediaType == .image {
            if asset?.mediaSubtypes == .photoLive {
                self.editLivePhoto(completion)
            }
            else {
                loadImage { [weak self] (image) in
                    self?.editImage(image, completion: completion)
                }
            }
        }
        else if asset?.mediaType == .video {
            loadVideo { [weak self] (video, audioMix) in
                self?.editVideo(video, audioMix: audioMix, completion: completion)
            }
        }
    }
}

extension BatchEditItem {
    fileprivate func loadImage(_ completion: @escaping ((UIImage?) -> Void)) {
        guard let asset = self.asset else {
            completion(nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        options.resizeMode = .none
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            print("\(progress)")
        }
        
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: options) { (image, info) in
            guard let image = image else {
                completion(nil)
                return
            }
            
            if let degraded = info?[PHImageResultIsDegradedKey] as? NSNumber, !degraded.boolValue {
                completion(image)
            }
        }
    }
    
    fileprivate func editImage(_ image: UIImage?, completion: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let image = image?.applyTransform(editItem.transform),
            let asset = self.asset
        else {
            completion(nil, nil)
            return
        }
        
        asset.requestContentEditingInput(with: nil) { (input, info) in
            guard let input = input else {
                completion(nil, nil)
                return
            }
            
            guard let dataInfo = "Edited".data(using: .utf8) else {
                completion(nil, nil)
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
                completion(nil, nil)
                return
            }
            
            completion(asset, contentEditingOutput)
        }
    }
}

extension BatchEditItem {
    fileprivate func loadLivePhoto(_ completion: @escaping ((PHLivePhoto?) -> Void)) {
        guard let asset = self.asset else {
            completion(nil)
            return
        }
        
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            print("\(progress)")
        }
        
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options, resultHandler: { (livePhoto, info) in
            completion(livePhoto)
        })
    }
    
    fileprivate func editLivePhoto(_ completion: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let asset = self.asset
            else {
                completion(nil, nil)
                return
        }
        
        asset.requestContentEditingInput(with: nil) { (input, info) in
            guard let input = input else {
                completion(nil, nil)
                return
            }
            
            guard let dataInfo = "Edited".data(using: .utf8) else {
                completion(nil, nil)
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
                    completion(nil, nil)
                    return
                }
                completion(asset, contentEditingOutput)
            })
        }
    }
    
    fileprivate func editLivePhoto(_ livePhoto: PHLivePhoto?, completion: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let livePhoto = livePhoto
        else {
            completion(nil, nil)
            return
        }

        let resources = PHAssetResource.assetResources(for: livePhoto)

        guard
            let videoResource = resources.first(where: { $0.type == PHAssetResourceType.pairedVideo }),
            let photoResource = resources.first(where: { $0.type == PHAssetResourceType.photo })
        else {
            completion(nil, nil)
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
                completion(nil, nil)
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
                completion(nil, nil)
                return
            }

            pairedPhoto = UIImage(data: photoData)
            retrievePairedResourcesHandler()
        }
    }
}

extension BatchEditItem {
    fileprivate func loadVideo(_ completion: @escaping ((AVAsset?, AVAudioMix?) -> Void)) {
        guard let asset = self.asset else {
            completion(nil, nil)
            return
        }
        
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            print("\(progress)")
        }
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (video, audioMix, info) in
            completion(video, audioMix)
        }
    }
    
    fileprivate func editVideo(_ video: AVAsset?, audioMix: AVAudioMix?, completion: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) {
        guard
            let video = video?.applyTransform(editItem.transform),
            let videoTrack = video.tracks(withMediaType: .video).first,
            let asset = asset
        else {
            completion(nil, nil)
            return
        }
        
        asset.requestContentEditingInput(with: nil) { (input, info) in
            guard let input = input else {
                completion(nil, nil)
                return
            }
            
            guard let dataInfo = "Edited".data(using: .utf8) else {
                completion(nil, nil)
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
                    completion(asset, contentEditingOutput)
                case .failed, .cancelled:
                    completion(nil, nil)
                default:
                    break
                }
            }
        }
    }
}

let kEditItemPreviewWidth: CGFloat = UIScreen.main.bounds.width * 0.9

class EditItem: NSObject {
    var transformItems = [TransformItem]()
    
    var hasChanges: Bool {
        return !transformItems.isEmpty //!transform.isIdentity
    }
    
    func addTransformItem(_ item: TransformItem) {
        transformItems.append(item)
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

extension PHAsset {
    //https://developer.apple.com/library/content/samplecode/UsingPhotosFramework/Listings/Shared_AssetViewController_swift.html
    func revertToOriginal() {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self)
            request.revertAssetContentToOriginal()
        }, completionHandler: { success, error in
            if !success { print("can't revert asset: \(String(describing: error))") }
        })
    }
}

extension UIImage {
    func flipHorizontally() -> UIImage {
        return withHorizontallyFlippedOrientation()
    }
    
    func flipVertically() -> UIImage {
        return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { (ctx) in
            guard let cgImage = self.cgImage else { return }
            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
            ctx.cgContext.scaleBy(x: 1, y: -1)
        }
    }
    
    func rotate(by degrees: CGFloat) -> UIImage {
        return applyTransform(CGAffineTransform(rotationAngle: degrees.degreesToRadians))
    }
    
    func rotate(with transform: CGAffineTransform) -> UIImage {
        let renderSize = size.applying(transform).magnitude
        return UIGraphicsImageRenderer(size: renderSize, format: imageRendererFormat).image { (ctx) in
            ctx.cgContext.translateBy(x: renderSize.width / 2, y: renderSize.height / 2)
            ctx.cgContext.rotate(by: transform.radians)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            if let cgImage = self.cgImage {
                ctx.cgContext.draw(cgImage, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
            }
        }
    }
    
    func applyTransform(_ transform: CGAffineTransform) -> UIImage {
        let renderSize = size.applying(transform).magnitude
        return UIGraphicsImageRenderer(size: renderSize, format: imageRendererFormat).image { (ctx) in
            ctx.cgContext.translateBy(x: renderSize.width / 2, y: renderSize.height / 2)
            ctx.cgContext.concatenate(transform)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            if let cgImage = self.cgImage {
                ctx.cgContext.draw(cgImage, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
            }
        }
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
extension UIImage {
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
