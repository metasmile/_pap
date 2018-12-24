//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import UIKit
import Vision
import AVFoundation

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

public protocol DepthDataSourceable:Sourceable {
    var asDepthData:AVDepthData? { get }
    var asDepthDataMap:CVPixelBuffer? { get }
}

public protocol RawDataSourceable:Sourceable {
    var asRawData:Data? { get }
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
            return ciImage ?? CIImage(image: self)
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
        return CIContext.shared.jpegRepresentation(of: self, colorSpace: self.colorSpace ?? CGColorSpaceCreateDeviceRGB())
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
        return autoreleasepool{
            return self.cgImage ?? CIContext.shared.createCGImage(self, from: extent)
        }
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
extension URL: ImageSourceable, DataSourceable, DepthDataSourceable, URLSourceable {
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

    public var asCGImage: CGImage? {
        guard let fileURL = self as CFURL? else {
            return nil
        }
        guard let source = CGImageSourceCreateWithURL(fileURL, nil) else {
            return nil
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 1, nil) else {
            return nil
        }
        return cgImage
    }

    public var asDepthData:AVDepthData? {
#if targetEnvironment(simulator)
        assert(false,"Use 'asDepthDataMap' instead.")
#else
        // Create a CGImageSource
        guard let source = CGImageSourceCreateWithURL(self as CFURL, nil) else {
            assert(false, "CGImageSourceCreateWithURL")
            return nil
        }

        guard let auxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeDisparity) as? [AnyHashable : Any] else {
//            assert(false, "CGImageSourceCopyAuxiliaryDataInfoAtIndex")
            return nil
        }

        // This is the star of the show!
        var depthData: AVDepthData

        do {
            // Get the depth data from the auxiliary data info
            depthData = try AVDepthData(fromDictionaryRepresentation: auxDataInfo)

        } catch {
            assert(false, "try AVDepthData(fromDictionaryRepresentation: auxDataInfo)")
            return nil
        }

        // Make sure the depth data is the type we want
        if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        }

        return depthData
#endif
    }

    public var asDepthDataMap:CVPixelBuffer? {
        #if targetEnvironment(simulator)
        let depthDataMap = asCGImage?.pixelBuffer()?.convertToDisparity32()
        depthDataMap?.normalize()
        return depthDataMap
        #else
        return asDepthData?.depthDataMap
        #endif
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
