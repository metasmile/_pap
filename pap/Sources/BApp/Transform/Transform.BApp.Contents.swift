//
//  Transform.App.Contents.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 8. 23..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class _TransformAppAsset: PHAssetItem<ImageEditStateValue> {
    fileprivate var editingContext: PHLivePhotoEditingContext?
    fileprivate var exportSession: AVAssetExportSession?
    
    func cancelProcessing() {
        editingContext?.cancel()
        editingContext = nil
        
        exportSession?.cancelExport()
        exportSession = nil
    }
}

//TODO: Uncommonize all, remove DispatchQueue.global().async
extension _TransformAppAsset: PHAssetImageEditable {

    func edit<T: ImageProcessable>(processor: T, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let asset = self.asset

        //TODO: apply iOS new api - CIImage.transform and CIContext().writeJPEGRepre....
        guard let image = asset.asUIImage?.applyTransform(self.editState.transform) else {
            completionHandler(nil, nil)
            return nil
        }

        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }

            DispatchQueue.global().async {
                // renderedContentURL supports only JPEG and MOV ...
                // so... always export JPEG
                //TODO: investigate PHAssetChangeRequest.creationRequestForAssetFromImage(url)
                let outputData = UIImageJPEGRepresentation(image, 1)

                guard (try? outputData?.write(to: item.output.renderedContentURL, options: .atomic)) != nil else {
                    completionHandler(nil, nil)
                    return
                }

                completionHandler(asset, item.output)
            }
        }
        return [PHAssetRequestID(forEditingInput: r)]
    }
}

extension _TransformAppAsset: PHAssetLivePhotoEditable {

    func edit<T:LivePhotoProcessable>(processor:T, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {

        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }
            
            self.editingContext = PHLivePhotoEditingContext(livePhotoEditingInput: item.input)
            let duration = self.editingContext?.duration.seconds
            self.editingContext?.frameProcessor = { frame, error in
                progressHandler?({
                    guard let duration = duration else { return nil }
                    return Float(frame.time.seconds / duration)
                }())
                let editItemConvertedCoordinates = StateValueSet<ImageEditStateValue>()
                for transformItem in self.editState.iterator(){
                    if let rotationItem = transformItem as? RotationTransformItem {
                        editItemConvertedCoordinates.append(RotationTransformItem(radians: -rotationItem.angle))
                    }
                    else {
                        editItemConvertedCoordinates.append(transformItem)
                    }
                }
                return frame.image.transformed(by: editItemConvertedCoordinates.transform)
            }

            self.editingContext?.saveLivePhoto(to: item.output, options: nil, completionHandler: { (success, error) in
                guard success else {
                    completionHandler(nil, nil)
                    return
                }
                completionHandler(self.asset, item.output)
            })
        }

        return [PHAssetRequestID(forEditingInput: r)]
    }

    func edit<T:LivePhotoAdvancedProcessor>(processor:T, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {

        guard let livePhoto = self.asset.asPHLivePhoto else {
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
                    let editItem = self?.editState,
                    let _ = pairedVideo?.applyTransform(editItem.transform),
                    let _ = pairedPhoto?.applyTransform(editItem.transform)
                    else { return }
        }

        var videoData = Data()
        var photoData = Data()

        var reqIDs = [PHAssetRequestID]()

        //
        let req1 = PHAssetResourceManager.default().requestData(for: videoResource, options: nil, dataReceivedHandler: { (data) in
            videoData.append(data)
        }) { (error) in
            guard error == nil else {
                completionHandler(nil, nil)
                return
            }

            let pairedVideoFileURL = FileURL.temp("pairedVideo", UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
            try? videoData.write(to: pairedVideoFileURL, options: Data.WritingOptions.atomicWrite)
            pairedVideo = AVAsset(url: pairedVideoFileURL)
            retrievePairedResourcesHandler()
        }
        reqIDs.append(PHAssetRequestID(forResourceData: req1))

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
        reqIDs.append(PHAssetRequestID(forResourceData: req2))

        return reqIDs
    }
}

extension _TransformAppAsset: PHAssetVideoEditable {
    func edit<T>(processor:T /*audioMix: AVAudioMix? = nil,*/, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
            where T:VideoProcessable {

        let asset = self.asset

        guard
                let video = asset.asAVAsset?.applyTransform(editState.transform),
                let videoTrack = video.tracks(withMediaType: .video).first

                else {
            completionHandler(nil, nil)
            return nil
        }

        var reqIDs = [PHAssetRequestID]()

        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }

            let videoComposition = AVMutableVideoComposition(propertiesOf: video)
            videoComposition.renderSize = videoTrack.naturalSize.applying(self.editState.transform).magnitude
            videoComposition.frameDuration = CMTimeMake(1, videoTrack.naturalTimeScale)
            
            self.exportSession = AVAssetExportSession.export(asset: video, videoComposition: videoComposition, outputURL: item.output.renderedContentURL, progressHandler: progressHandler, completionHandler: { (success) in
                if success {
                    completionHandler(asset, item.output)
                }
                else {
                    completionHandler(nil, nil)
                }
            })
        }

        reqIDs.append(PHAssetRequestID(forEditingInput: r))
        return reqIDs
    }
}


let kEditItemPreviewWidth: CGFloat = UIScreen.main.bounds.width * 0.9

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

        return UIGraphicsImageRenderer(size: rotatedSize, format: imageRendererFormat).imageWithCurrentContext { (cgContext) in
            guard let cgImage = self.cgImage else { return }
            cgContext.concatenate(transform)
            cgContext.draw(cgImage, in: CGRect(origin: .zero, size: rotatedSize))
        } ?? self
    }
}
