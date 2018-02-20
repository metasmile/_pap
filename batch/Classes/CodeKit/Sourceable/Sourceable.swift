//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import UIKit

public protocol Sourceable {

}

public protocol ImageSourceable:Sourceable {
    var asImage:UIImage? { get }
}

public protocol VideoSourceable:Sourceable {
    var asVideo:AVAsset? { get }
}

public protocol LivePhotoSourceable:Sourceable {
    var asLivePhoto:PHLivePhoto? { get }
}

public protocol DataSourceable:Sourceable {
    var asData:Data? { get }
}

public protocol RemoteSourceable:Sourceable {
    var asURL:URL? { get }
}

public protocol PHAssetSourceable:Sourceable {
    var asAsset:PHAsset? { get }
}

public protocol StringSourceable:Sourceable {
    var asString:String? { get }
}

extension UIImage: ImageSourceable, DataSourceable, RemoteSourceable, PHAssetSourceable, StringSourceable {
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
    public var asImage:UIImage? {
        return UIImage(contentsOfFile: self.path)
    }

    public var asData:Data? {
        do {
            return try Data(contentsOf: self)
        } catch {
            return nil
        }
    }

    public var asURL:URL? {
        return self
    }
}

extension String: ImageSourceable, DataSourceable, RemoteSourceable {
    public var asImage:UIImage? {
        return nil
    }
    public var asData:Data? { get { return nil } }
    public var asURL:URL? { get { return nil } }
}
