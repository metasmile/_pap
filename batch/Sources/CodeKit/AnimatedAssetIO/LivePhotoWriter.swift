//
// Created by BLACKGENE on 9/16/16.
// Copyright (c) 2016 stells. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

public typealias LivePhotoWriterResultHandler = ((Bool, URL?, URL?, Error?) -> ())?
public typealias LivePhotoWriterAssetSavedHandler = ((Bool, String?, Error?) -> ())?
public typealias LivePhotoWriterAssetSavedAndFetchedHandler = ((Bool, PHLivePhoto?, PHAsset?, Error?) -> ())?

public class LivePhotoWriter {

    public var jpegQuality:CGFloat = 0.8

    // MARK: Create PHLivePhoto
    public func createLivePhotoFromImages(paths: [String]
            , indexOfTitle: Int
        , progress: ((Progress) -> ())?
            , fps: Int32
        , created: ((_ livePhoto:PHLivePhoto?) -> ())?
    ) {

        self.writeLivePhotoFromImages(photoPaths: paths, indexOfTitle: indexOfTitle, progress: progress, fps: fps) {
            success, imageURL, pairedVideoURL, _ in

            if success{
                self.createLivePhoto(imageURL: imageURL!, withPairedVideo: pairedVideoURL!, completion: created)
            }else{
                created?(nil)
            }
        }
    }

    public func createLivePhotoFromVideo(videoPath: String
            , timeLocationOfTitle: Double
            , created: ((PHLivePhoto?) -> ())?
    ) {
        self.writeLivePhotoFromVideo(videoPath: videoPath, timeLocationOfTitle: timeLocationOfTitle, completion:{
            success, imageURL, pairedVideoURL, error in

            if success{
                self.createLivePhoto(imageURL: imageURL!, withPairedVideo: pairedVideoURL!, completion: created)
            }else{
                created?(nil)
            }
        })
    }

    // MARK: Save LivePhoto to Library
    public func saveLivePhotoFromImages(paths: [String]
            , indexOfTitle: Int
            , progress: ((Progress) -> ())?
            , fps: Int32
            , saved: LivePhotoWriterAssetSavedHandler
            , andFetched: LivePhotoWriterAssetSavedAndFetchedHandler
    ) {
        self.writeLivePhotoFromImages(photoPaths: paths, indexOfTitle: indexOfTitle, progress: progress, fps: fps) {
            success, imageURL, pairedVideoURL, _ in

            self.saveLivePhoto(imageURL: imageURL!, withPairedVideo: pairedVideoURL!, completion: saved, fetchCompletion:andFetched)
        }

    }

    public func saveLivePhotoFromVideo(videoPath: String
            , timeLocationOfTitle : Double
            , saved: LivePhotoWriterAssetSavedHandler
            , andFetched: LivePhotoWriterAssetSavedAndFetchedHandler
    ) {
        self.writeLivePhotoFromVideo(videoPath: videoPath, timeLocationOfTitle: timeLocationOfTitle, completion:{
            success, imageURL, pairedVideoURL, error in

            self.saveLivePhoto(imageURL: imageURL!, withPairedVideo: pairedVideoURL!, completion: saved, fetchCompletion:andFetched)
        })
    }

    // MARK: PhotoKit Procedures
    func saveLivePhoto(imageURL: URL
            , withPairedVideo pairedVideoURL: URL
            , completion: LivePhotoWriterAssetSavedHandler
            , fetchCompletion: LivePhotoWriterAssetSavedAndFetchedHandler
    ) {

        var createdAssetsLocalIdentifier: String?

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()

            let options = PHAssetResourceCreationOptions()
            request.addResource(with: .pairedVideo, fileURL: pairedVideoURL, options: options)
            request.addResource(with: .photo, fileURL: imageURL, options: options)

            createdAssetsLocalIdentifier = request.placeholderForCreatedAsset?.localIdentifier

        }, completionHandler: { success, error in
            completion?(success, createdAssetsLocalIdentifier, error)

            if fetchCompletion != nil {
                if let createdAsset = PHAsset.fetchAssets(withLocalIdentifiers: [createdAssetsLocalIdentifier!], options: nil).firstObject
                    , success{

                    let livePhotoOptions = PHLivePhotoRequestOptions()
                    livePhotoOptions.deliveryMode = .highQualityFormat

                    PHImageManager.default().requestLivePhoto(for: createdAsset
                            , targetSize: .zero
                            , contentMode: .default
                            , options: livePhotoOptions
                            , resultHandler: { livePhoto, info in

                        if info?[PHImageCancelledKey] as? Bool ?? false
                                || info?[PHImageErrorKey] as? Bool ?? false
                                || info?[PHImageResultIsDegradedKey] as? Bool ?? false {
                            return
                        }

                        fetchCompletion?(livePhoto != nil, livePhoto, createdAsset, error)
                    })
                } else {
                    fetchCompletion?(success, nil, nil, error)
                }
            }

            createdAssetsLocalIdentifier = nil
        })
    }

    func createLivePhoto(imageURL: URL
            , withPairedVideo pairedVideoURL: URL
            , completion: ((PHLivePhoto?) -> ())?
    ) {

        PHLivePhoto.request(withResourceFileURLs: [imageURL, pairedVideoURL], placeholderImage: nil, targetSize: .zero, contentMode: .default) { livePhoto, info in
            if let livePhoto = livePhoto{
                if info[PHImageCancelledKey] as? Bool ?? true && info[PHLivePhotoInfoIsDegradedKey] as? Bool ?? true {
                    completion?(livePhoto)
                }
            }else{
                completion?(nil)
            }
        }
    }

    // MARK: Core Utils
    func writeLivePhotoFromImages(photoPaths: [String]
            , indexOfTitle: Int
            , progress: ((Progress) -> Void)?
            , fps: Int32
            , completion: LivePhotoWriterResultHandler
    ) {

        if let titleImagePath = indexOfTitle < photoPaths.count-1 ? photoPaths[indexOfTitle] : photoPaths.first{
            let builder = TimeLapsBuilder(imagePaths: photoPaths)
            builder.fps = fps
            builder.build({ p in progress?(p) }, success: { url in

                self.writeLivePhoto(photoPath: titleImagePath, withVideo: url.path, completion: completion)

              }, failure: { error in
                completion?(false, nil, nil, error)
            })
        }else{
            completion?(false, nil, nil, nil)
        }
    }

    func writeLivePhotoFromVideo(videoPath: String
            , timeLocationOfTitle: Double
            , completion: LivePhotoWriterResultHandler
    ) {

        let asset = AVURLAsset(url:URL(fileURLWithPath: videoPath))

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let tempPath = self.tempWritingPathByAppedingSuffix(lastPathComponent: (videoPath as NSString).lastPathComponent, suffix: "", ext: nil).path
        let destExtractedImagePath = self.tempWritingPathByAppedingSuffix(lastPathComponent: tempPath, suffix: "_extracted_image", ext: "jpg").path
        let time = NSValue(time: CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration) * (timeLocationOfTitle), asset.duration.timescale))

        generator.generateCGImagesAsynchronously(forTimes: [time]) { [weak self] _, image, _, result, error in
            if let image = image
            , let data = UIImageJPEGRepresentation(UIImage(cgImage: image), self?.jpegQuality ?? 0.8)
            , result != .succeeded && error == nil {
                do{
                    try data.write(to: URL(fileURLWithPath: destExtractedImagePath))

                    self?.writeLivePhoto(photoPath: destExtractedImagePath, withVideo: videoPath, completion: completion)
                }catch {}
            }
        }
    }


    private let dispatchQueue = DispatchQueue(label: "com.stells.livephotowriter.write")

    func writeLivePhoto(photoPath: String
            , withVideo videoPath: String
            , completion: LivePhotoWriterResultHandler
    ) {

        dispatchQueue.async {
            let destImageURL = self.tempWritingPathByAppedingSuffix(lastPathComponent: (photoPath as NSString).lastPathComponent, suffix:"_encoded_livephoto", ext:nil)

            if FileManager.default.fileExists(atPath: destImageURL.path) {
                try? FileManager.default.removeItem(atPath: destImageURL.path)
            }

            let destPairedVideoURL = self.tempWritingPathByAppedingSuffix(lastPathComponent: (videoPath as NSString).lastPathComponent, suffix:"_encoded_livephoto", ext:nil)

            if FileManager.default.fileExists(atPath: destPairedVideoURL.path) {
                try? FileManager.default.removeItem(atPath:destPairedVideoURL.path)
            }

            let uuid = UUID().uuidString

            LivePhotoImageResourceWriter.write(from: URL(fileURLWithPath: photoPath), to: URL(fileURLWithPath: destImageURL.path), assetIdentifier: uuid)

            LivePhotoImageResourceWriter.write(from: URL(fileURLWithPath: videoPath), to: URL(fileURLWithPath: destPairedVideoURL.path), assetIdentifier: uuid)
            
            DispatchQueue.main.async{
                completion?(true, destImageURL, destPairedVideoURL, nil)
            }
        }
    }

    func tempWritingPathByAppedingSuffix(lastPathComponent:String
                                         ,suffix:String?
                                         ,ext:String?
    ) -> URL {


        let _lastPathComponent:NSString = lastPathComponent as NSString

        let path = (_lastPathComponent.deletingLastPathComponent as NSString).appendingPathComponent(
                ((_lastPathComponent.deletingPathExtension as NSString).appending(suffix ?? "") as NSString).appendingPathExtension(ext ?? _lastPathComponent.pathExtension) ?? ""
        )

        return URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(path)
    }

}
