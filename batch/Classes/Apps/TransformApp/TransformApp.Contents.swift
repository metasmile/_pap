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

//TODO: generalize later into PHAssetResourcable
private class _PHAssetRequestID {
    enum DefaultValue{
        static let forImage = PHInvalidImageRequestID
        static let forResourceData = PHInvalidAssetResourceDataRequestID
        static let forEditingInput = Int.min
    }

    fileprivate var forImage:PHImageRequestID
    fileprivate var forResourceData:PHAssetResourceDataRequestID
    fileprivate var forEditingInput:PHContentEditingInputRequestID

    init(forImage: PHImageRequestID = DefaultValue.forImage,
         forResourceData: PHAssetResourceDataRequestID = DefaultValue.forResourceData,
         forEditingInput: PHContentEditingInputRequestID = DefaultValue.forEditingInput) {

        self.forImage = forImage
        self.forResourceData = forResourceData
        self.forEditingInput = forEditingInput
    }
}

public class TransformAppEditItem: NSObject, TaskParamable {
    fileprivate var requestIDs = [_PHAssetRequestID]()

    var asset: PHAsset?
    var editItem = TransformEditItem()
    var indexSection:(Int, Int)?
}

extension TransformAppEditItem {

    func runEditing(_ progressHandler: ((Float) -> Void)? = nil, _ completionHandler: @escaping (PHAsset?, PHContentEditingOutput?) -> Void) {

        //REMIND: from ios9, addObserver will be automatically unregister without dealloc
        NotificationCenter.default.addObserver(forName: RemoteSourceFetchNotification.Name.fetchBagan, object: asset, queue: nil) { notification in
            if let _requestId = notification.userInfo?[RemoteSourceFetchNotification.UserInfo.Key.imageRequestID] as? PHImageRequestID{
                self.requestIDs.append(_PHAssetRequestID(forImage:_requestId))
            }
        }

        var requestIDs:[_PHAssetRequestID]?

        if asset?.mediaType == .image {
            if asset?.mediaSubtypes.contains(.photoLive) == true {
                requestIDs = editLivePhoto(completionHandler)
            }
            else {
                requestIDs = editImage(asset?.asImage, completion: completionHandler)
            }
        }
        else if asset?.mediaType == .video {
            requestIDs = editVideo(asset?.asVideo, completion: completionHandler)
        }

        if let _requestIDs = requestIDs {
            self.requestIDs += _requestIDs
        }
    }

    func cancelEditing() {

        for req in requestIDs{
            if req.forImage != _PHAssetRequestID.DefaultValue.forImage{
                PHImageManager.default().cancelImageRequest(req.forImage)
            }

            if req.forEditingInput != _PHAssetRequestID.DefaultValue.forEditingInput{
                asset?.cancelContentEditingInputRequest(req.forEditingInput)
            }

            if req.forResourceData != _PHAssetRequestID.DefaultValue.forResourceData{
                PHAssetResourceManager.default().cancelDataRequest(req.forResourceData)
            }
        }
    }

    fileprivate func editImage(_ image: UIImage?, completion completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) -> [_PHAssetRequestID]? {
        guard
            let image = image?.applyTransform(editItem.transform),
            let asset = self.asset
        else {
            completionHandler(nil, nil)
            return nil
        }

        let req = asset.requestContentEditingInput(with: nil) { (input, info) in
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

            DispatchQueue.global().async {
                // renderedContentURL supports only JPEG and MOV ...
                // so... always export JPEG
                let outputData = UIImageJPEGRepresentation(image, 1)

                guard (try? outputData?.write(to: contentEditingOutput.renderedContentURL, options: .atomic)) != nil else {
                    completionHandler(nil, nil)
                    return
                }

                completionHandler(asset, contentEditingOutput)
            }
        }

        return [_PHAssetRequestID(forEditingInput: req)]
    }
}

extension TransformAppEditItem {
    fileprivate func editLivePhoto(_ completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) -> [_PHAssetRequestID]? {
        guard
            let asset = self.asset
            else {
                completionHandler(nil, nil)
                return nil
        }

        let req = asset.requestContentEditingInput(with: nil) { (input, info) in
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
                let editItemConvertedCoordinates = TransformEditItem()
                self.editItem.transformItems.forEach({ (transformItem) in
                    if let rotationItem = transformItem as? RotationTransformItem {
                        editItemConvertedCoordinates.addTransformItem(RotationTransformItem(radians: -rotationItem.angle))
                    }
                    else {
                        editItemConvertedCoordinates.addTransformItem(transformItem)
                    }
                })
                return frame.image.transformed(by: editItemConvertedCoordinates.transform)
            }

            editingContext?.saveLivePhoto(to: contentEditingOutput, options: nil, completionHandler: { (success, error) in
                guard success else {
                    completionHandler(nil, nil)
                    return
                }
                completionHandler(asset, contentEditingOutput)
            })
        }

        return [_PHAssetRequestID(forEditingInput: req)]
    }

    fileprivate func editLivePhoto(_ livePhoto: PHLivePhoto?, completion completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) -> [_PHAssetRequestID]? {
        guard
            let livePhoto = livePhoto
        else {
            completionHandler(nil, nil)
            return nil
        }

        let resources = PHAssetResource.assetResources(for: livePhoto)

        guard
            let videoResource = resources.first(where: { $0.type == PHAssetResourceType.pairedVideo }),
            let photoResource = resources.first(where: { $0.type == PHAssetResourceType.photo })
        else {
            completionHandler(nil, nil)
            return nil
        }

        var pairedVideo: AVAsset?
        var pairedPhoto: UIImage?
        let retrievePairedResourcesHandler = { [weak self] in
            guard
                let editItem = self?.editItem,
                let _ = pairedVideo?.applyTransform(editItem.transform),
                let _ = pairedPhoto?.applyTransform(editItem.transform)
            else { return }


        }

        var videoData = Data()
        var photoData = Data()

        var reqIDs = [_PHAssetRequestID]()

        //
        let req1 = PHAssetResourceManager.default().requestData(for: videoResource, options: nil, dataReceivedHandler: { (data) in
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
        reqIDs.append(_PHAssetRequestID(forResourceData: req1))

        //
        let req2 = PHAssetResourceManager.default().requestData(for: photoResource, options: nil, dataReceivedHandler: { (data) in
            photoData.append(data)
        }) { (error) in
            guard error == nil else {
                completionHandler(nil, nil)
                return
            }

            pairedPhoto = UIImage(data: photoData)
            retrievePairedResourcesHandler()
        }
        reqIDs.append(_PHAssetRequestID(forResourceData: req2))

        return reqIDs
    }
}

extension TransformAppEditItem {
    fileprivate func editVideo(_ video: AVAsset?, audioMix: AVAudioMix? = nil, completion completionHandler: @escaping ((PHAsset?, PHContentEditingOutput?) -> Void)) -> [_PHAssetRequestID]?{
        guard
            let video = video?.applyTransform(editItem.transform),
            let videoTrack = video.tracks(withMediaType: .video).first,
            let asset = asset
        else {
            completionHandler(nil, nil)
            return nil
        }

        var reqIDs = [_PHAssetRequestID]()

        let r = asset.requestContentEditingInput(with: nil) { (input, info) in
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
            exportSession?.audioMix = audioMix
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

        reqIDs.append(_PHAssetRequestID(forEditingInput: r))

        return reqIDs
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

    func perform(_ progress: ((Float) -> Void)? = nil, _ completion: ((TransformAppTaskRespondable?) -> Void)? = nil) {
        guard let batchEditItem = batchEditItem else {
            completion?(nil)
            return
        }

        batchEditItem.runEditing(progress) { (asset, contentEditingOutput) in
            var result: TransformAppTaskRespondable?
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = TransformAppTaskRespondable(asset: asset ,/* indexPath: batchEditItem.indexPath*/ contentEditingOutput: contentEditingOutput)
            }
            completion?(result)
        }
    }

    override func cancel() {
        super.cancel()

        batchEditItem?.cancelEditing()
    }
}
