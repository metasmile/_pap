//
// Created by BLACKGENE on 15.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos
import PhotosUI

//https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_still_and_live_photos/capturing_and_saving_live_photos
/*
CaptureProcessor
*/
typealias CaptureProcessorResult = [CaptureProcessorResultKey:Any]
typealias CaptureProcessorCompletionHandler = (_ succeed:Bool, _ result:CaptureProcessorResult?) -> ()

struct CaptureProcessorResultKey: Hashable, Equatable, RawRepresentable {
    public typealias RawValue = Int
    public private(set) var rawValue: RawValue
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension CaptureProcessorResultKey{
    static let photoURL = CaptureProcessorResultKey(rawValue:PHAssetResourceType.photo.rawValue)
    static let pairedVideoURL = CaptureProcessorResultKey(rawValue:PHAssetResourceType.pairedVideo.rawValue)
}

struct CaptureProcessorParameter{
    let videoDeviceInput:AVCaptureDeviceInput?
    var deviceOrientation:UIDeviceOrientation
}

class CaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    var completionHandler:CaptureProcessorCompletionHandler?
    lazy var captureQueue = DispatchQueue(label: "com.stells.internal."+String(describing:type(of: self)), qos: .utility)

    let parameter:CaptureProcessorParameter

    required init(parameter:CaptureProcessorParameter){
        self.parameter = parameter
    }

    final func exportStillImageOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) -> URL? {

        if let data = photo.fileDataRepresentation()
        , let ciImage = data.asCIImage {
            var transform = CGAffineTransform.identity

            if self.parameter.videoDeviceInput?.device.position == .front{
                transform = transform.concatenating(ciImage.orientationTransform(for: .downMirrored))
            }

            switch parameter.deviceOrientation{
                case .landscapeRight:
                    transform = transform.concatenating(ciImage.orientationTransform(for: .right))
                case .landscapeLeft:
                    transform = transform.concatenating(ciImage.orientationTransform(for: .left))
                case .portraitUpsideDown:
                    transform = transform.concatenating(ciImage.orientationTransform(for: .upMirrored))
                    transform = transform.concatenating(ciImage.orientationTransform(for: .downMirrored))
                case .portrait, .faceUp, .faceDown, .unknown:
                    break
            }

            let ciImageWriting = transform == CGAffineTransform.identity
                    ? ciImage
                    : ciImage.transformed(by: transform)

            let url = FileURL.temp(UUID().uuidString, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
            if ciImageWriting.writeJPEGRepresentationOriginally(to: url){
                return url
            }
        }
        return nil
    }
}

final class CameraViewStillPhotoCaptureProcessor: CaptureProcessor {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let url = self.exportStillImageOutput(output, didFinishProcessingPhoto: photo, error: error) else{
            return
        }

        captureQueue.async {
            let signal = AsyncSignal()

            signal.begin()
            PHPhotoLibrary.shared().performChanges({

                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }, completionHandler: { (success, info) in
                self.completionHandler?(success, [
                    CaptureProcessorResultKey.photoURL:url
                ])
                signal.end()
            })
            signal.waitUntilEnd()
        }
    }
}

final class CameraViewLivePhotoCaptureProcessor: CaptureProcessor {
    private var photoURL: URL?

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureQueue.async {
            guard let url = self.exportStillImageOutput(output, didFinishProcessingPhoto: photo, error: error) else{
                return
            }
            self.photoURL = url
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        captureQueue.async {
            guard let photoURL = self.photoURL else { return }

            let signal = AsyncSignal()

            signal.begin()
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true

                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, fileURL: photoURL, options: options)
                creationRequest.addResource(with: .pairedVideo, fileURL: outputFileURL, options: options)
            }, completionHandler: { (success, info) in
                self.completionHandler?(success, [
                    CaptureProcessorResultKey.photoURL:photoURL
                    , CaptureProcessorResultKey.pairedVideoURL:outputFileURL
                ])
                signal.end()
            })
            signal.waitUntilEnd()
        }
    }
}