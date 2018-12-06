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

extension AVCapturePhoto {
    var isDepthPhoto: Bool {
        if let _ = depthData {
            return true
        }
        else if #available(iOS 12.0, *), let _ = portraitEffectsMatte {
            return true
        }
        return false
    }
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
    
    static func metadata(of photo: AVCapturePhoto, with processor: CaptureProcessor) -> [String: Any] {
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
            , value: [processor.param.metadataComment ?? "", type(of: processor).ExifUserCommentIdentifier].joined(separator: type(of: processor).ExifUserCommentSeparator).trimmed
        )
        if let location = LocationManager.shared.location {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            dateFormatter.dateFormat = "yyyy:MM:dd"
            let isoDate = dateFormatter.string(from: location.timestamp)
            
            dateFormatter.dateFormat = "HH:mm:ss.SSSSSS"
            let isoTime = dateFormatter.string(from: location.timestamp)
            
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSLatitude, value: abs(location.coordinate.latitude))
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSLatitudeRef, value: location.coordinate.latitude < 0 ? "S" : "N")
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSLongitude, value: abs(location.coordinate.longitude))
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSLongitudeRef, value: location.coordinate.longitude < 0 ? "W" : "E")
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSAltitude, value: abs(location.altitude))
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSAltitudeRef, value: location.altitude < 0 ? 1 : 0)
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSTimeStamp, value: isoTime)
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.GPS
                , property: ImageMetadata.Property.GPSDateStamp, value: isoDate)
            
            if let heading = LocationManager.shared.heading {
                metadata = metadata.updateMetadata(
                    dictionary: ImageMetadata.Dictionary.GPS
                    , property: ImageMetadata.Property.GPSImgDirection, value: heading.trueHeading)
                metadata = metadata.updateMetadata(
                    dictionary: ImageMetadata.Dictionary.GPS
                    , property: ImageMetadata.Property.GPSImgDirectionRef, value: "T")
            }
        }
        // https://forums.developer.apple.com/thread/87700
        if photo.isDepthPhoto {
            metadata = metadata.updateMetadata(
                dictionary: ImageMetadata.Dictionary.Exif
                , property: ImageMetadata.Property.ExifCustomRendered
                , value: 8
            )
        }
        return metadata
    }
    
    private final func exportDataOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) -> Data? {
        if #available(iOS 12.0, *) {
            class CaptureProcessorFileDataRepresentation: NSObject, AVCapturePhotoFileDataRepresentationCustomizer {
                private var processor: CaptureProcessor
                
                init(_ processor: CaptureProcessor) {
                    self.processor = processor
                    
                    super.init()
                }
                
                func replacementDepthData(for photo: AVCapturePhoto) -> AVDepthData? {
                    return photo.depthData
                }
                
                func replacementMetadata(for photo: AVCapturePhoto) -> [String : Any]? {
                    return CaptureProcessor.metadata(of: photo, with: processor)
                }
                
                func replacementPortraitEffectsMatte(for photo: AVCapturePhoto) -> AVPortraitEffectsMatte? {
                    return photo.portraitEffectsMatte
                }
            }
            return photo.fileDataRepresentation(with: CaptureProcessorFileDataRepresentation(self))
        }
        else {
            return photo.fileDataRepresentation(withReplacementMetadata: CaptureProcessor.metadata(of: photo, with: self)
                , replacementEmbeddedThumbnailPhotoFormat: nil
                , replacementEmbeddedThumbnailPixelBuffer: nil
                , replacementDepthData: photo.depthData)
        }
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
                if photo.isDepthPhoto {
                    let url = FileURL.temp(UUID().uuidString, UTI(rawValue: AVFileType.heif.rawValue), group: FileURL.fileAndQueuePrivateGroup())
                    var options = [CIImageRepresentationOption: Any]()
                    options[kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption] = 1.0
                    
                    if let depthData = photo.depthData {
                        options[CIImageRepresentationOption.avDepthData] = depthData
                    }
                    if #available(iOS 12.0, *), let portraitEffectsMatte = photo.portraitEffectsMatte {
                        options[CIImageRepresentationOption.avPortraitEffectsMatte] = portraitEffectsMatte
                    }
                    
                    if let _ = try? CIContext().writeHEIFRepresentation(of: ciImage, to: url, format: CIFormat.RGBA8, colorSpace: ciImage.defaultColorSpace, options: options) {
                        return url
                    }
                }
                else {
                    let url = FileURL.temp(UUID().uuidString, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
                    if ciImage.writeJPEGRepresentationOriginally(to: url) {
                        return url
                    }
                }
            }
        }
        return nil
    }
    
    final func portraitEffectMattePhoto(_ photo: AVCapturePhoto) -> Data? {
        if #available(iOS 12.0, *) {
            guard var portraitEffectsMatte = photo.portraitEffectsMatte else { return nil }
            
            if let orientation = photo.metadata[ String(kCGImagePropertyOrientation) ] as? UInt32 {
                portraitEffectsMatte = portraitEffectsMatte.applyingExifOrientation( CGImagePropertyOrientation(rawValue: orientation)! )
            }
            let portraitEffectsMattePixelBuffer = portraitEffectsMatte.mattingImage
            let portraitEffectsMatteImage = CIImage( cvImageBuffer: portraitEffectsMattePixelBuffer, options: [ .auxiliaryPortraitEffectsMatte: true ] )
            guard let linearColorSpace = CGColorSpace(name: CGColorSpace.linearSRGB) else { return nil }
            
            return CIContext().heifRepresentation(of: portraitEffectsMatteImage, format: .RGBA8, colorSpace: linearColorSpace, options: [ CIImageRepresentationOption.portraitEffectsMatteImage: portraitEffectsMatteImage ] )
        }
        else {
            return nil
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
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, fileURL: url, options: options)
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
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, fileURL: compressedURL, options: options)
                    
                    // Add the RAW (DNG) file as an altenate resource.
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
