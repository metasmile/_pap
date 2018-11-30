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
    static let alternatePhotoURL = CaptureProcessorResultKey(rawValue:PHAssetResourceType.alternatePhoto.rawValue)
}

struct CaptureProcessorParam {
    let videoDeviceInput:AVCaptureDeviceInput?
    var deviceOrientation:UIDeviceOrientation
    var metadataComment:String?
}

class CaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {

    static var ExifUserCommentIdentifier:String{
        return "com.stells.batch.CaptureProcessor"
    }
    static var ExifUserCommentSeparator:String{
        return ","
    }

    var completionHandler:CaptureProcessorCompletionHandler?
    lazy var captureQueue = DispatchQueue(label: "com.stells.internal."+String(describing:type(of: self)), qos: .utility)

    let param: CaptureProcessorParam

    required init(param: CaptureProcessorParam){
        self.param = param
    }
    
    private final func exportDataOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) -> Data? {
        /*
         Metadata Config
         */
        var metadata = photo.metadata
        //TODO: should add CLLocation but currently hold on
        if let displayName = Bundle.main.displayName {
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.TIFF
                , property: ImageMetadata.Property.TIFFSoftware
                , value: "\(displayName) \(Bundle.main.shortVersionString ?? "") (\(Bundle.main.version ?? ""))"
            )
        }
        metadata = metadata.updateMetadata(
            dictionary: ImageMetadata.Dictionary.Exif
            , property: ImageMetadata.Property.ExifUserComment
            , value: [param.metadataComment ?? "", type(of: self).ExifUserCommentIdentifier].joined(separator: type(of: self).ExifUserCommentSeparator).trimmed
        )
        
        return photo.fileDataRepresentation(withReplacementMetadata: metadata
            , replacementEmbeddedThumbnailPhotoFormat: nil
            , replacementEmbeddedThumbnailPixelBuffer: nil
            , replacementDepthData: nil)
    }

    final func exportStillImageOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) -> URL? {
        /*
            Writing
        */
        if let data = exportDataOutput(output, didFinishProcessingPhoto: photo, error: error) {
            if photo.isRawPhoto {
                let url = FileURL.temp(UUID().uuidString, nil, group: FileURL.fileAndQueuePrivateGroup()).appendingPathExtension("dng")
                if let _ = try? data.write(to: url) {
                    return url
                }
            }
            else if let ciImage = data.asCIImage {
                let url = FileURL.temp(UUID().uuidString, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
                if ciImage.writeJPEGRepresentationOriginally(to: url) {
                    return url
                }
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

final class CameraViewRawPhotoCaptureProcessor: CaptureProcessor {
    // https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_still_and_live_photos/capturing_photos_in_raw_format
    
    var rawImageFileURL: URL?
    var compressedFileURL: URL?
    
    // Hold on to the separately delivered RAW file and compressed photo data until capture is finished.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        captureQueue.async {
            if photo.isRawPhoto {
                self.rawImageFileURL = self.exportStillImageOutput(output, didFinishProcessingPhoto: photo, error: error)
            }
            else {
                self.compressedFileURL = self.exportStillImageOutput(output, didFinishProcessingPhoto: photo, error: error)
            }
        }
    }
    
    // After both RAW and compressed versions are delivered, add them to the Photos Library.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
            captureQueue.async {
                guard let rawURL = self.rawImageFileURL, let compressedURL = self.compressedFileURL else { return }
                
                let signal = AsyncSignal()
                
                signal.begin()
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, fileURL: compressedURL, options: nil)
                    
                    // Add the RAW (DNG) file as an altenate resource.
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    creationRequest.addResource(with: .alternatePhoto, fileURL: rawURL, options: options)
                }, completionHandler: { (success, info) in
                    self.completionHandler?(success, [
                        CaptureProcessorResultKey.photoURL:compressedURL
                        , CaptureProcessorResultKey.alternatePhotoURL:rawURL
                ])
                signal.end()
            })
            signal.waitUntilEnd()
        }
    }
}
