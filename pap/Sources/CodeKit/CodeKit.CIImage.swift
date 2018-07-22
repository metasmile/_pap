//
// Created by BLACKGENE on 21/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

extension CIImage{
    public var defaultColorSpace: CGColorSpace{
        return self.colorSpace ?? CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
    }

    @discardableResult
    public func writeJPEGRepresentationOriginally(to:URL, options:[AnyHashable : Any] = [:]) -> Bool{
        var _options = options
        _options[kCGImageDestinationLossyCompressionQuality] = 1.0
        return self.writeJPEGRepresentation(to: to, options: _options)
    }

    @discardableResult
    public func writeJPEGRepresentation(to:URL, options:[AnyHashable : Any] = [:]) -> Bool{
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