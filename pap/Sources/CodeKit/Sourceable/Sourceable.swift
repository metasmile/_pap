//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import UIKit
import Vision

public protocol Sourceable {

}

public protocol ImageSourceable:Sourceable {
    var asUIImage:UIImage? { get }
    var asCIImage:CIImage? { get }
    var asCGImage:CGImage? { get }
}

extension ImageSourceable{
    public var asCGImage: CGImage? {
        return nil
    }
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
        return self.jpegData(compressionQuality: 1)
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
        return autoreleasepool {
            return CIImage(image: self)
        }
    }
}

extension CALayer: ImageSourceable {
    public var asUIImage:UIImage? { get { return nil } }
    public var asData:UIImage? { get { return nil } }
    public var asCIImage: CIImage? {
        return asData?.asCIImage
    }
}

extension CIImage: DataSourceable, ImageSourceable, VisionSourceable{
    public var asData:Data? {
        return CIContext().jpegRepresentation(of: self, colorSpace: self.colorSpace ?? CGColorSpaceCreateDeviceRGB())
    }

    public var asUIImage:UIImage? {
        return autoreleasepool{
            //little more faster
            if let cgImage = self.cgImage{
                return UIImage(cgImage: cgImage)
            }
            return UIImage(ciImage: self)
        }
    }

    public var asCIImage: CIImage? {
        return self
    }

    public var asCGImage: CGImage? {
        return CIContext().createCGImage(self, from: extent)
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
        return autoreleasepool{
            return CIImage(data:self)
        }
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
        return autoreleasepool{
            return CIImage(contentsOf: self)
        }
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
        return autoreleasepool{
            if let url = asURL {
                return CIImage(contentsOf: url)
            }
            return nil
        }
    }
}
