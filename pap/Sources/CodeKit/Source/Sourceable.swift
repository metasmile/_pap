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
    var asUIImage:UIImage? { get }
    var asCIImage:CIImage? { get }
}

public protocol BundleImageSourceable:Sourceable {
    var asUIImageNamed:UIImage? { get }
    var asUIImageContentOfFile:UIImage? { get }
}

public protocol VideoSourceable:Sourceable {
    var asAVAsset:AVAsset? { get }
}

public protocol LivePhotoSourceable:Sourceable {
    var asPHLivePhoto:PHLivePhoto? { get }
}

public protocol DataSourceable:Sourceable {
    var asData:Data? { get }
}

public protocol URLSourceable:Sourceable {
    var asURL:URL? { get }
}


public protocol PHAssetSourceable:Sourceable {
    var asPHAsset:PHAsset? { get }
}

public protocol StringSourceable:Sourceable {
    var asString:String? { get }
}

extension UIImage: ImageSourceable, DataSourceable, URLSourceable, PHAssetSourceable, StringSourceable {
    public var asUIImage:UIImage? { get { return self } }
    public var asData:Data? {
        return UIImageJPEGRepresentation(self, 0.7)
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
    public var asPHAsset:PHAsset? { get { return nil } }

    public var asCIImage: CIImage? {
        if let cgImage = self.cgImage{
            return CIImage(cgImage: cgImage)
        }
        return nil
    }
}

extension CALayer: ImageSourceable {
    public var asUIImage:UIImage? { get { return nil } }
    public var asData:UIImage? { get { return nil } }
    public var asCIImage: CIImage? {
        return asData?.asCIImage
    }
}

extension CIImage: DataSourceable{
    public var asData:Data? {
        return CIContext().jpegRepresentation(of: self, colorSpace: self.colorSpace ?? CGColorSpaceCreateDeviceRGB())
    }
}

extension Data: ImageSourceable, DataSourceable, URLSourceable, StringSourceable {
    public var asUIImage:UIImage? { get { return nil } }
    public var asData:Data? { get { return self } }
    public var asURL:URL? { get { return nil } }
    public var asString:String? {
        get {
            return self.base64EncodedString()
        }
    }
    public var asCIImage: CIImage?{
        return CIImage(data:self)
    }
}
extension URL: ImageSourceable, DataSourceable, URLSourceable {
    public var asUIImage:UIImage? {
        return UIImage(contentsOfFile: self.absoluteString)
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

    public var asCIImage: CIImage?{
        return CIImage(contentsOf: self)
    }
}

extension String: ImageSourceable, BundleImageSourceable, DataSourceable, URLSourceable {
    public var asUIImage:UIImage? {
        if let image = asUIImageNamed {
            return image
        }

        if let image = asUIImageContentOfFile {
            return image
        }

        assert(false, "Does not supported this string format. \(self)")
        return nil
    }

    public var asUIImageNamed:UIImage? {
        return UIImage(named: self)
    }

    public var asUIImageContentOfFile:UIImage? {
        return UIImage(contentsOfFile: self.asBundlePath)
    }

    public var asData:Data? { return nil }

    public var asURL:URL? {
        return URL(string: self)
    }

    public var asCIImage: CIImage?{
        if let url = asURL {
            return CIImage(contentsOf: url)
        }
        return nil
    }
}
