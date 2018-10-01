//
// Created by BLACKGENE on 29/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import MobileCoreServices

extension PHAsset {
    public var localIdentifierWithoutSplitter: String {
        return localIdentifier.remove("/")
    }

    public var resources:[PHAssetResource]{
        return PHAssetResource.assetResources(for: self)
    }

    public var isAdjusted:Bool{
        let resources = self.resources
        if resources.count > 1{
            for r in resources{
                if r.type == .adjustmentData || r.type == .adjustmentBasePairedVideo || r.type == .adjustmentBasePhoto{
                    return true
                }
            }
        }
        return false
    }

    //https://developer.apple.com/library/content/samplecode/UsingPhotosFramework/Listings/Shared_AssetViewController_swift.html
    public func revertToOriginal() {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self)
            request.revertAssetContentToOriginal()
        }, completionHandler: { success, error in
            if !success { print("can't revert asset: \(String(describing: error))") }
        })
    }

    public func requestToDelete(wait:Bool=false, completion:((Bool, Error?) -> Swift.Void)? = nil) {
        if wait{
            do{
                try PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetChangeRequest.deleteAssets(NSArray(object: self))
                }
                completion?(true,nil)
            }catch let e {
                completion?(false, e)
            }
        }else{
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(NSArray(object: self))
            }, completionHandler: completion)
        }
    }


    public func shareWithDefaultUIActivities(completion:UIKit.UIActivityViewControllerCompletionWithItemsHandler?=nil){

        if self.mediaType == .video{
            let videoRequestOptions = PHVideoRequestOptions()
            videoRequestOptions.isNetworkAccessAllowed = true
            videoRequestOptions.deliveryMode = .automatic

            PHImageManager.default().requestAVAsset(forVideo: self, options: videoRequestOptions, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    UIActivityViewController.share(activityItems: [urlAsset.url as URL], excludedActivityTypes:[UIActivityType.saveToCameraRoll])
                }
            })
        } else if self.imageType == .livePhoto{

            let livePhotoRequestOptions = PHLivePhotoRequestOptions()
            livePhotoRequestOptions.deliveryMode = .opportunistic
            livePhotoRequestOptions.isNetworkAccessAllowed = true

            PHImageManager.default().requestLivePhoto(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: livePhotoRequestOptions, resultHandler: { (livePhoto, info) in
                if let livePhoto = livePhoto{
                    UIActivityViewController.share(activityItems: [livePhoto])
                }
            })

        } else{
            let defaultImageRequestOptions = PHImageRequestOptions()
            defaultImageRequestOptions.isNetworkAccessAllowed = true
            defaultImageRequestOptions.isSynchronous = false
            defaultImageRequestOptions.deliveryMode = .opportunistic
            defaultImageRequestOptions.resizeMode = .exact

            PHImageManager.default().requestImageData(for: self, options: defaultImageRequestOptions) { data, s, orientation, dictionary in
                if let data = data{
                    UIActivityViewController.share(activityItems: [data], excludedActivityTypes:[UIActivityType.saveToCameraRoll])
                }
            }
        }
    }

    var pixelSize: CGSize {
        return CGSize(width: pixelWidth, height: pixelHeight)
    }

    public final func fetchAdjustmentData(completionHandler:@escaping (PHAdjustmentData?) -> Void){
        let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ -> Bool in
            return true
        }

        self.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
            completionHandler(contentEditingInput?.adjustmentData)
        })
    }

    @discardableResult
    public final func writeJPEGRepresentation(to url:URL, transformMetadata: @escaping (([String : Any]) -> [String : Any]?), completion:@escaping (Bool) -> Void ) -> PHContentEditingInputRequestID {
        return self.requestContentEditingInput(with: nil) { input, dictionary in

            guard let image = input?.fullSizeImageURL?.asCIImage
            , let metadata = transformMetadata(image.properties)
            , input?.uniformTypeIdentifier == UTI.jpeg.rawValue else {
                completion(false)
                return
            }

            completion(image.settingProperties(metadata).writeJPEGRepresentation(to: url))
        }
    }

    @discardableResult
    public final func fetchCIImage(completion: @escaping ((CIImage?) -> Void)) -> PHContentEditingInputRequestID {
        return self.requestContentEditingInput(with: nil) { input, dictionary in
            completion(input?.fullSizeImageURL?.asCIImage)
        }
    }

    /*
    asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (eidtingInput, info) in
                    if let input = eidtingInput, let imgURL = input.fullSizeImageURL {
                        // imgURL
                        print(imgURL)

                        //file:///var/mobile/Media/PhotoData/Mutations/DCIM/109APPLE/IMG_9931/Adjustments/FullSizeRender.jpg
                    }
                    signal.end()
           }
               */
}

public enum PHAssetImageType: Int {
    case notImage
    case stillImage
    case livePhoto
    case animatedGIF
    case burst
}

public enum PHAssetVideoType: Int {
    case notVideo
    case screenRecordedVideo
    case mp4Video
    case undefined
}

extension PHAsset {
    var uniformTypeIdentifier: String? {
        return value(forKey: "uniformTypeIdentifier") as? String
    }
    
    var imageType: PHAssetImageType {
        guard mediaType == .image else { return .notImage }

        if uniformTypeIdentifier == UTCoreTypes.GIF {
            return .animatedGIF
        }
        else if representsBurst {
            return .burst
        }
        else if mediaSubtypes.contains(.photoLive) {
            return .livePhoto
        }
        else {
            return .stillImage
        }
    }

    var videoType: PHAssetVideoType {
        guard mediaType == .video else { return .notVideo }

        if uniformTypeIdentifier == UTCoreTypes.MPEG4{
            let m = UIScreen.main
            if Double(m.bounds.size.width/m.bounds.size.height).round(toPlaces: 2) == (Double(pixelWidth)/Double(pixelHeight)).round(toPlaces: 2)
            , Int(m.bounds.size.width) < pixelWidth && pixelWidth < Int(m.nativeBounds.width) {
                return .screenRecordedVideo

            }else {
                return .mp4Video
            }
        }

        return .undefined

    }
}

extension PHAsset {
    static func fetchAsset(withLocalIdentifier localIdentifier: String, options: PHFetchOptions? = nil) -> PHAsset? {
        return PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: options).firstObject
    }
}
