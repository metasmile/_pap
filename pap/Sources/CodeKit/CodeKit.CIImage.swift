//
// Created by BLACKGENE on 21/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

extension CIImage{
    convenience init?(image: UIImage?) {
        guard let image = image else {
            return nil
        }
        self.init(image: image)
    }

    convenience init?(cvPixelBuffer: CVPixelBuffer?) {
        guard let cvPixelBuffer = cvPixelBuffer else {
            return nil
        }
        self.init(cvPixelBuffer: cvPixelBuffer)
    }

    convenience init?(cgImage: CGImage?) {
        guard let cgImage = cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    //utils
    public var defaultColorSpace: CGColorSpace{
        return self.colorSpace ?? CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
    }

    @discardableResult
    public func writeJPEGRepresentationOriginally(to:URL, options:[CIImageRepresentationOption : Any] = [:]) -> Bool{
        var _options = options
        _options[kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption] = 1.0
        return self.writeJPEGRepresentation(to: to, options: _options)
    }

    @discardableResult
    public func writeJPEGRepresentation(to:URL, options:[CIImageRepresentationOption : Any] = [:]) -> Bool{
        do {
            try CIContext().writeJPEGRepresentation(of: self
                    , to:to
                    , colorSpace: defaultColorSpace
                , options: options)

            return true

        } catch {
            return false
        }
    }

    func applyFilter(ciFilter: CIFilter?) -> CIImage {
        guard let filter = ciFilter, filter.inputKeys.contains(kCIInputImageKey) else { return self }
        filter.setValue(self, forKey: kCIInputImageKey)
        return filter.outputImage ?? self
    }
}
