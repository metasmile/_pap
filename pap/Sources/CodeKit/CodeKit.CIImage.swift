//
// Created by BLACKGENE on 21/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

extension CIContext {
    static var shared: CIContext = CIContext(options: nil)
}

extension CIImage{
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
            try CIContext.shared.writeJPEGRepresentation(of: self
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

extension CIImage {
    func resizeAspectFit(_ size: CGSize) -> CIImage {
        let resize = AVMakeRect(aspectRatio: extent.size, insideRect: CGRect(origin: .zero, size: size)).size
        let scale = min(resize.width / extent.width, resize.height / extent.height)
        return transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func resizeAspectFit(in bounds: CGRect) -> CIImage {
        let resize = AVMakeRect(aspectRatio: extent.size, insideRect: bounds)
        let scale = min(resize.width / extent.width, resize.height / extent.height)
        let transform = CGAffineTransform(translationX: resize.origin.x, y: resize.origin.y).scaledBy(x: scale, y: scale)
        return transformed(by: transform)
    }
}

extension CIImage {
    var asMTLTexture: MTLTexture? {
        guard
            let texture = MTLUtility.makeTexture(width: Int(extent.width), height: Int(extent.height)),
            let commandBuffer = MTLContext.shared.commandQueue?.makeCommandBuffer()
        else { return nil }
        CIContext.shared.render(self, to: texture, commandBuffer: commandBuffer, bounds: extent, colorSpace: defaultColorSpace)
        commandBuffer.commit()
        return texture
    }
}

extension CIImage {
    func applyMetalShader(_ functionName: String, params parameters: [Any]? = nil) -> CIImage? {
        guard
            let inputTexture = self.asMTLTexture,
            let outputTexture = MTLUtility.makeTexture(width: Int(extent.width), height: Int(extent.height))
        else { return nil }
        
        var uniformValues = [MTLBuffer]()
        for var value in parameters ?? [] {
            guard let buffer = MTLContext.shared.device.makeBuffer(bytes: &value, length: MemoryLayout.size(ofValue: value), options: MTLResourceOptions.cpuCacheModeWriteCombined) else { continue }
            uniformValues.append(buffer)
        }
        
        MTLUtility.commitComputeShader(functionName, input: inputTexture, output: outputTexture, with: uniformValues)
        
        return CIImage(mtlTexture: outputTexture, options: [
            CIImageOption.colorSpace: defaultColorSpace
        ])
    }
}
