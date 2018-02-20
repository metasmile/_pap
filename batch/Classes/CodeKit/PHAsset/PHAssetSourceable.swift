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
        }
    }
}

extension PHAsset: ImageSourceable, DataSourceable, RemoteSourceable, PHAssetSourceable, VideoSourceable, LivePhotoSourceable {
    public var asUIImage:UIImage? {
        get {
            let signal = TaskDefaultSignal()
            signal.begin()
            
            var result: UIImage? = nil
            let imageRequestID = PHImageManager.default().requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: fullResolutionImageRequestOptions) { (image, info) in
                result = image
                
                _ = signal.end()
            }
            
            let userInfo: [String: Any] = [
                RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID
            ]
            NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.fetchBagan, object: self, userInfo: userInfo)
            
            signal.stopUntilEnd()
            
            return result
        }
    }

    public var asData:Data? { get { return nil } }
    public var asURL:URL? { get { return nil } }
    public var asPHAsset:PHAsset? { get { return self } }

    private var fullResolutionImageRequestOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.progressHandler = { progress, error, stop, info in
            let userInfo: [String: Any] = [
                RemoteSourceFetchNotification.UserInfo.Key.progress: progress
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
                RemoteSourceFetchNotification.UserInfo.Key.progress: progress
            ]
            NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.progressChanged, object: self, userInfo: userInfo)
        }
        return options
    }
    
    public var asAVAsset: AVAsset? {
        let signal = TaskDefaultSignal()
        signal.begin()
        
        var result: AVAsset?
        let imageRequestID = PHImageManager.default().requestAVAsset(forVideo: self, options: highQualityVideoRequestOptions) { (video, audioMix, info) in
            result = video
            _ = signal.end()
        }
        
        let userInfo: [String: Any] = [
            RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID
        ]
        NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.fetchBagan, object: self, userInfo: userInfo)
        
        signal.stopUntilEnd()
        return result
    }
    
    private var highQualityLivePhotoRequestOptions: PHLivePhotoRequestOptions {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.progressHandler = { progress, error, stop, info in
            let userInfo: [String: Any] = [
                RemoteSourceFetchNotification.UserInfo.Key.progress: progress
            ]
            NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.progressChanged, object: self, userInfo: userInfo)
        }
        return options
    }
    
    public var asPHLivePhoto: PHLivePhoto? {
        let signal = TaskDefaultSignal()
        signal.begin()
        
        var result: PHLivePhoto?
        let imageRequestID = PHImageManager.default().requestLivePhoto(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: highQualityLivePhotoRequestOptions, resultHandler: { (livePhoto, info) in
            result = livePhoto
            _ = signal.end()
        })
        
        let userInfo: [String: Any] = [
            RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID
        ]
        NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.fetchBagan, object: self, userInfo: userInfo)
        
        signal.stopUntilEnd()
        return result
    }
}
