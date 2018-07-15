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

class CaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    var completionHandler:CaptureProcessorCompletionHandler?
    lazy var captureQueue = DispatchQueue(label: "com.stells.internal."+#file, qos: .utility)
}

final class CameraViewStillPhotoCaptureProcessor: CaptureProcessor {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let url = FileURL.temp(UUID().uuidString, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
        guard let _ = try? photo.fileDataRepresentation()?.write(to: url) else { return }

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