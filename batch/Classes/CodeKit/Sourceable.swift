//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public protocol Sourceable {

}

public protocol ImageSourceable:Sourceable {
    var asImage:UIImage? { get }
}

public protocol DataSourceable:Sourceable {
    var asData:Data? { get }
}

public protocol RemoteSourceable:Sourceable {
    var asURL:URL? { get }
}

public protocol PhotosSourceable:Sourceable {
    var asAsset:PHAsset? { get }
}

public protocol StringSourceable:Sourceable {
    var asString:String? { get }
}

extension UIImage: ImageSourceable, DataSourceable, RemoteSourceable, PhotosSourceable, StringSourceable {
    public var asImage:UIImage? { get { return self } }
    public var asData:Data? {
        get {
            return UIImagePNGRepresentation(self)
        }
    }
    public var asURL:URL? { get { return nil } }
    public var asString:String? {
        get {
            if let data = self.asData {
                return Data(data).base64EncodedString()
            }
            return nil
        }
    }
    public var asAsset:PHAsset? { get { return nil } }
}

extension CALayer: ImageSourceable {
    public var asImage:UIImage? { get { return nil } }
    public var asData:UIImage? { get { return nil } }
}

extension Data: ImageSourceable, DataSourceable, RemoteSourceable, StringSourceable {
    public var asImage:UIImage? { get { return nil } }
    public var asData:Data? { get { return self } }
    public var asURL:URL? { get { return nil } }
    public var asString:String? {
        get {
            return self.base64EncodedString()
        }
    }
}

extension URL: ImageSourceable, DataSourceable, RemoteSourceable {
    public var asImage:UIImage? { get { return nil } }
    public var asData:Data? { get { return nil } }
    public var asURL:URL? { get { return nil } }
}

extension String: ImageSourceable, DataSourceable, RemoteSourceable {
    public var asImage:UIImage? { get { return nil } }
    public var asData:Data? { get { return nil } }
    public var asURL:URL? { get { return nil } }
}

public struct RemoteSourceFetchNotification {
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

extension PHAsset: ImageSourceable, DataSourceable, RemoteSourceable, PhotosSourceable  {
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
                RemoteSourceFetchNotification.UserInfo.Key.imageRequestID: imageRequestID,
                RemoteSourceFetchNotification.UserInfo.Key.progress: progress
            ]
            NotificationCenter.default.post(name: RemoteSourceFetchNotification.Name.progressChanged, object: self, userInfo: userInfo)
        }
        return options
    }
}

