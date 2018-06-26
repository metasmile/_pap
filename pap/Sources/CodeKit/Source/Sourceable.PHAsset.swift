//
// Created by BLACKGENE on 25/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public struct RemoteSourceFetchNotification {
    enum Name {
        static let fetchBagan = Notification.Name("RemoteSourceFetchNotificationFetchBagan")
        static let progressChanged = Notification.Name("RemoteSourceFetchNotificationProgressChanged")
    }

    struct UserInfo {
        enum Key {
            static let progress = "progress"
            static let imageRequestID = "imageRequestID"
            static let asset = "asset"
        }
    }
}

extension PHAsset {
    func requestThumbnailImage(targetSize: CGSize, contentMode: PHImageContentMode = .aspectFit) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        
        var result: UIImage?
        PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: contentMode, options: options) { (image, info) in
            result = image
        }
        return result
    }
    
    func requestImage(targetSize: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .aspectFit, options: PHImageRequestOptions? = PHAsset.highQualityImageRequestOptions, _ async: AsyncManualSignalable = AsyncSignal()) -> (requestID: PHImageRequestID, image: UIImage?) {
        async.begin()
        
        var result: UIImage? = nil
        let imageRequestID = PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: contentMode, options: options) { (image, info) in
            guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
            
            result = image
            
            _ = async.end()
        }
        
        let userInfo: [String: Any] = [
            RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID,
            RemoteSourceFetchNotification.UserInfo.Key.asset: self
        ]
        NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.fetchBagan, object: self, userInfo: userInfo)
        
        async.waitUntilEnd()
        return (imageRequestID, result)
    }
}

extension PHAsset: ImageSourceable, DataSourceable, URLSourceable, PHAssetSourceable, VideoSourceable, LivePhotoSourceable {
    public var asUIImage:UIImage? {
        get {
            return self.requestImage(targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: PHAsset.highQualityImageRequestOptions).1
        }
    }

    //TODO: standardize all
    public var asData:Data? {
        if let url = self.asURL {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    public var asURL:URL? {
        var returningURL:URL?

        let signal = AsyncSignal()
        let m = self.mediaType

        // Video
        if .video == m{

            signal.begin()
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original

            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    returningURL = urlAsset.url as URL
                }
                signal.end()
            })
        }
        // Image
        else if .image == m {

            // Live Photo
            if self.mediaSubtypes.contains(.photoLive){
                //TODO: import from https://github.com/metasmile/AnimatedAssetIO
            }

            signal.begin()
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }

            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                returningURL = contentEditingInput!.fullSizeImageURL as URL?
                signal.end()
            })

        }else{
            assert(false, "Not implemented yet.\(self.mediaType), \(self.mediaSubtypes)")
        }

        return returningURL
    }
    public var asPHAsset:PHAsset? { return self }
    public var asCIImage: CIImage? {
        guard let image = asUIImage else { return nil }
        return CIImage(image: image)
    }

    static var highQualityImageRequestOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.progressHandler = { progress, error, stop, info in
            let userInfo: [String: Any] = [
                RemoteSourceFetchNotification.UserInfo.Key.progress: Float(progress),
                RemoteSourceFetchNotification.UserInfo.Key.asset: self
            ]
            NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.progressChanged, object: self, userInfo: userInfo)
        }
        return options
    }
    
    private var highQualityVideoRequestOptions: PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            let userInfo: [String: Any] = [
                RemoteSourceFetchNotification.UserInfo.Key.progress: Float(progress),
                RemoteSourceFetchNotification.UserInfo.Key.asset: self
            ]
            NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.progressChanged, object: self, userInfo: userInfo)
        }
        return options
    }
    
    public var asAVAsset: AVAsset? {
        let signal = AsyncSignal()
        signal.begin()
        
        var result: AVAsset?
        let imageRequestID = PHImageManager.default().requestAVAsset(forVideo: self, options: highQualityVideoRequestOptions) { (video, audioMix, info) in
            result = video
            _ = signal.end()
        }
        
        let userInfo: [String: Any] = [
            RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID,
            RemoteSourceFetchNotification.UserInfo.Key.asset: self
        ]
        NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.fetchBagan, object: self, userInfo: userInfo)
        
        signal.waitUntilEnd()
        return result
    }
    
    private var highQualityLivePhotoRequestOptions: PHLivePhotoRequestOptions {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            let userInfo: [String: Any] = [
                RemoteSourceFetchNotification.UserInfo.Key.progress: Float(progress),
                RemoteSourceFetchNotification.UserInfo.Key.asset: self
            ]
            NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.progressChanged, object: self, userInfo: userInfo)
        }
        return options
    }
    
    public var asPHLivePhoto: PHLivePhoto? {
        let signal = AsyncSignal()
        signal.begin()
        
        var result: PHLivePhoto?
        let imageRequestID = PHImageManager.default().requestLivePhoto(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: highQualityLivePhotoRequestOptions, resultHandler: { (livePhoto, info) in
            guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
            
            result = livePhoto
            _ = signal.end()
        })
        
        let userInfo: [String: Any] = [
            RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID,
            RemoteSourceFetchNotification.UserInfo.Key.asset: self
        ]
        NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.fetchBagan, object: self, userInfo: userInfo)
        
        signal.waitUntilEnd()
        return result
    }
}
