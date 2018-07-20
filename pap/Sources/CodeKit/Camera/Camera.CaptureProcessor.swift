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
//    var deviceOrientation:UIDeviceOrientation
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

            let device = UIDevice.current

            var imageOrientation = UIImageOrientation.up
            if (device.orientation == UIDeviceOrientation.landscapeLeft){
                imageOrientation = UIImageOrientation.downMirrored

            } else if (device.orientation == UIDeviceOrientation.landscapeRight){
                imageOrientation = UIImageOrientation.upMirrored

            } else if (device.orientation == UIDeviceOrientation.portrait){
                imageOrientation = UIImageOrientation.leftMirrored

            } else if (device.orientation == UIDeviceOrientation.portraitUpsideDown){
                imageOrientation = UIImageOrientation.rightMirrored
            }

            transform = transform.concatenating(ciImage.orientationTransform(for: imageOrientation.cgImagePropertyOrientation))

            if self.parameter.videoDeviceInput?.device.position == .front{
                transform = transform.concatenating(ciImage.orientationTransform(for: .downMirrored))
            }

            print(device.orientation.rawValue, device.orientation == .unknown)
            print(transform == CGAffineTransform.identity)

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

protocol Orientatable{
    var imageOrientation:UIImageOrientation {get}
    var cgImagePropertyOrientation:CGImagePropertyOrientation {get}
    var deviceOrientation:UIDeviceOrientation {get}
}

extension UIDeviceOrientation: Orientatable {
    var avCaptureVideoOrientation:AVCaptureVideoOrientation{
        switch self {
            case .landscapeLeft:
                return .landscapeLeft
            case .portrait, .faceUp, .unknown:
                return .portrait
            case .portraitUpsideDown, .faceDown:
                return .portraitUpsideDown
            case .landscapeRight:
                return .landscapeRight
        }
    }

    var imageOrientation:UIImageOrientation {
        switch self {
            case .landscapeLeft:
                return .up
            case .portrait, .faceUp:
                return .right
            case .portraitUpsideDown, .faceDown:
                return .left
            case .landscapeRight:
                return .down
            case .unknown:
                return .up
        }
    }

    var cgImagePropertyOrientation:CGImagePropertyOrientation{
        return self.imageOrientation.cgImagePropertyOrientation
    }

    var deviceOrientation:UIDeviceOrientation{
        return self
    }
}

extension UIImageOrientation{
    var imageOrientation:UIImageOrientation {
        return self
    }

    var deviceOrientation:UIDeviceOrientation{
        switch self {
            case .up, .upMirrored: return .landscapeLeft
            case .right, .rightMirrored: return .portrait
            case .left, .leftMirrored: return .portraitUpsideDown
            case .down, .downMirrored: return .landscapeRight
        }
    }

    var cgImagePropertyOrientation:CGImagePropertyOrientation{
        switch self {
            case .up: return .up
            case .upMirrored: return .upMirrored
            case .down: return .down
            case .downMirrored: return .downMirrored
            case .left: return .left
            case .leftMirrored: return .leftMirrored
            case .right: return .right
            case .rightMirrored: return .rightMirrored
        }
    }
}


extension CGImagePropertyOrientation{
    var imageOrientation:UIImageOrientation{
        switch self {
            case .up: return .up
            case .upMirrored: return .upMirrored
            case .down: return .down
            case .downMirrored: return .downMirrored
            case .left: return .left
            case .leftMirrored: return .leftMirrored
            case .right: return .right
            case .rightMirrored: return .rightMirrored
        }
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

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureQueue.async {
            let url = FileURL.temp(UUID().uuidString, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
            guard let _ = try? photo.fileDataRepresentation()?.write(to: url) else { return }
            self.photoURL = url
        }
    }
}