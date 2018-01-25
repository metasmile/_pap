//
// Created by BLACKGENE on 25/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

private struct _RemoteSourceFetchNotification {
    enum Name {
        static let progressChanged = Notification.Name("RemoteSourceFetchNotificationProgressChanged")
    }

    struct UserInfo {
        enum Key {
            static let progress = "progress"
            static let imageRequestID = "imageRequestID"
        }
    }
}

extension PHAsset: ImageSourceable, DataSourceable, RemoteSourceable, PHAssetSourceable {
    public var asImage:UIImage? {
        get {
            var result: UIImage? = nil
            PHImageManager.default().requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: fullResolutionImageRequestOptions) { (image, info) in
                result = image
            }
            return result
        }
    }

    public var asData:Data? { get { return nil } }
    public var asURL:URL? { get { return nil } }
    public var asAsset:PHAsset? { get { return self } }

    private var fullResolutionImageRequestOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.progressHandler = { progress, error, stop, info in
            guard let imageRequestID = info?[PHImageResultRequestIDKey] as? UInt32 else { return }
            let userInfo: [String: Any] = [
                _RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID,
                _RemoteSourceFetchNotification.UserInfo.Key.progress: progress
            ]
            NotificationCenter.default.post(name: _RemoteSourceFetchNotification.Name.progressChanged, object: self, userInfo: userInfo)
        }
        return options
    }
}
