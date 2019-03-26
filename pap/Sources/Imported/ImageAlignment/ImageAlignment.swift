//
//  ImageAlignment.swift
//  pixelstabilizer
//
//  Created by Hyojin Mo on 2017. 11. 2..
//  Copyright © 2017년 Codeful. All rights reserved.
//
//  https://developer.apple.com/documentation/vision
//  https://developer.apple.com/videos/play/wwdc2017/510/
//

import UIKit
import Vision

public class ImageAlignment {
    static let sharedCIContext = CIContext.shared
    
    public struct StabilizationMode: OptionSet, Hashable {
        public let rawValue: Int
        
        public static let none = StabilizationMode(rawValue: 0)
        public static let homographic = StabilizationMode(rawValue: 1 << 0)
        public static let translation = StabilizationMode(rawValue: 1 << 1)
        public static let crop = StabilizationMode(rawValue: 1 << 2)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

@available(iOS 11.0, *)
public extension UIImage {
    func stabilize(with image: UIImage?, mode: ImageAlignment.StabilizationMode = .translation) -> UIImage {
        if mode.contains(.translation) {
            return stabilizeTranslation(with: image, crop: mode.contains(.crop))
        }
        else if mode.contains(.homographic) {
            return stabilizeHomographic(with: image, crop: mode.contains(.crop))
        }
        else {
            return self
        }
    }

    @objc
    func stabilizeHomographic(with image: UIImage?, crop: Bool) -> UIImage {
        guard let matrix = ImageAlignment.homographicTransform(image, onto: self) else { return self }
        guard let ciImage = self.asCIImage, let cgimage = ImageAlignment.sharedCIContext.createCGImage(ciImage.applyHomographic(matrix, crop: crop), from: ciImage.extent) else { return self }
        return UIImage(cgImage: cgimage)
    }

    @objc
    func stabilizeTranslation(with image: UIImage?, crop: Bool) -> UIImage {
        guard let transform = ImageAlignment.translationTransform(image, onto: self) else { return self }
        guard let ciImage = self.asCIImage, let cgimage = ImageAlignment.sharedCIContext.createCGImage(ciImage.applyTranslation(transform, crop: crop), from: ciImage.extent) else { return self }
        return UIImage(cgImage: cgimage)
    }
}

@available(iOS 11.0, *)
public extension CIImage {
    func stabilize(with image: CIImage, mode: ImageAlignment.StabilizationMode) -> CIImage {
        if mode.contains(.translation) {
            return stabilizeTranslation(with: image, crop: mode.contains(.crop))
        }
        else if mode.contains(.homographic) {
            return stabilizeHomographic(with: image, crop: mode.contains(.crop))
        }
        else {
            return image
        }
    }
    
    @objc
    func stabilizeHomographic(with image: CIImage, crop: Bool) -> CIImage {
        let matrix = ImageAlignment.homographicTransform(image, onto: self)
        return self.applyHomographic(matrix, crop: crop)
    }
    
    @objc
    func stabilizeTranslation(with image: CIImage, crop: Bool) -> CIImage {
        let transform = ImageAlignment.translationTransform(image, onto: self)
        return self.applyTranslation(transform, crop: crop)
    }
}

@available(iOS 11.0, *)
extension ImageAlignment {
    static func homographicTransform(_ floating: UIImage?, onto reference: UIImage) -> matrix_float3x3? {
        guard let floatingImage = floating?.asCIImage, let referenceImage = reference.asCIImage else { return nil }
        return homographicTransform(floatingImage, onto: referenceImage)
    }
    
    static func homographicTransform(_ floating: CIImage, onto reference: CIImage) -> matrix_float3x3? {
        let request = VNHomographicImageRegistrationRequest(targetedCIImage: floating)
        let requestHandler = VNImageRequestHandler(ciImage: reference)
        
        try? requestHandler.perform([request])
        
        guard let results = request.results, let observation = results.first as? VNImageHomographicAlignmentObservation else { return nil }
        return observation.warpTransform
    }
    
    static func homographicTransform(_ floating: CVPixelBuffer, onto reference: CVPixelBuffer) -> matrix_float3x3? {
        let request = VNHomographicImageRegistrationRequest(targetedCVPixelBuffer: floating)
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: reference)
        
        try? requestHandler.perform([request])
        
        guard let results = request.results, let observation = results.first as? VNImageHomographicAlignmentObservation else { return nil }
        return observation.warpTransform
    }
}

@available(iOS 11.0, *)
extension ImageAlignment {
    static func translationTransform(_ floating: UIImage?, onto reference: UIImage) -> CGAffineTransform? {
        guard let floatingImage = floating?.asCIImage, let referenceImage = reference.asCIImage else { return nil }
        return translationTransform(floatingImage, onto: referenceImage)
    }
    
    static func translationTransform(_ floating: CIImage, onto reference: CIImage) -> CGAffineTransform? {
        let request = VNTranslationalImageRegistrationRequest(targetedCIImage: floating)
        let requestHandler = VNImageRequestHandler(ciImage: reference)
        
        try? requestHandler.perform([request])
        
        guard let results = request.results, let observation = results.first as? VNImageTranslationAlignmentObservation else { return nil }
        return observation.alignmentTransform
    }
    
    static func translationTransform(_ floating: CVPixelBuffer, onto reference: CVPixelBuffer) -> CGAffineTransform? {
        let request = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: floating)
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: reference)
        
        try? requestHandler.perform([request])
        
        guard let results = request.results, let observation = results.first as? VNImageTranslationAlignmentObservation else { return nil }
        return observation.alignmentTransform
    }
}

@available(iOS 11.0, *)
extension CIImage {
    fileprivate struct WarpMatrix {
        var translation: float2 = float2(0)
        var matrix: float3x3 = float3x3(0)
        var size: float2
        var clampRange: float2
        
        init(matrix: float3x3, size: float2, clampRange: float2) {
            self.matrix = matrix
            self.translation = float2(0)
            self.size = size
            self.clampRange = clampRange
        }
        
        init(translation: float2, size: float2, clampRange: float2) {
            self.matrix = float3x3(0)
            self.translation = translation
            self.size = size
            self.clampRange = clampRange
        }
    }
    
    func applyHomographic(_ matrix: matrix_float3x3?, crop: Bool) -> CIImage {
        let clamp: CGPoint = CGPoint(x: extent.size.minLength / 20, y: extent.size.minLength / 20)
        let croppedRect = crop ? extent.insetBy(dx: clamp.x / 2, dy: clamp.y / 2) : extent
        
        let transform = CGAffineTransform.identity.scaledBy(x: extent.width / croppedRect.width, y: extent.height / croppedRect.height).translatedBy(x: (croppedRect.width - extent.width) / 2, y: (croppedRect.height - extent.height) / 2)
        
        return ({ () -> CIImage? in
            guard let matrix = matrix else { return nil }
            var value = WarpMatrix(matrix: matrix, size: float2(Float(extent.width), Float(extent.height)), clampRange: float2(x: Float(clamp.x), y: Float(clamp.y)))
            
            var uniformValues = [MTLBuffer]()
            if let buffer = MTLContext.shared.device.makeBuffer(bytes: &value, length: MemoryLayout<WarpMatrix>.size(ofValue: value), options: MTLResourceOptions.cpuCacheModeWriteCombined) {
                uniformValues.append(buffer)
            }
            
            return self.applyMetalShader(vetexFunction: "warpHomographic", vertexUniforms: uniformValues)
        }() ?? self).cropped(to: croppedRect).transformed(by: transform)
    }
    
    func applyTranslation(_ translation: CGAffineTransform?, crop: Bool) -> CIImage {
        let clamp: CGPoint = CGPoint(x: extent.size.minLength / 20, y: extent.size.minLength / 20)
        let croppedRect = crop ? extent.insetBy(dx: clamp.x / 2, dy: clamp.y / 2) : extent
        
        let transform = CGAffineTransform.identity.scaledBy(x: extent.width / croppedRect.width, y: extent.height / croppedRect.height).translatedBy(x: (croppedRect.width - extent.width) / 2, y: (croppedRect.height - extent.height) / 2)
        
        return ({ () -> CIImage? in
            guard let translation = translation else { return nil }
            var value = WarpMatrix(translation: float2(x: Float(translation.tx / extent.width), y: Float(translation.ty / extent.height)), size: float2(Float(extent.width), Float(extent.height)), clampRange: float2(x: Float(clamp.x / extent.width), y: Float(clamp.y / extent.height)))
            
            var uniformValues = [MTLBuffer]()
            if let buffer = MTLContext.shared.device.makeBuffer(bytes: &value, length: MemoryLayout<WarpMatrix>.size(ofValue: value), options: MTLResourceOptions.cpuCacheModeWriteCombined) {
                uniformValues.append(buffer)
            }
            
            return self.applyMetalShader(vetexFunction: "warpTranslation", vertexUniforms: uniformValues)
        }() ?? self).cropped(to: croppedRect).transformed(by: transform)
    }
}

extension CIVector {
    static func `init`(float3x3: float3x3) -> CIVector {
        let values = [
            CGFloat(float3x3.columns.0.x),
            CGFloat(float3x3.columns.0.y),
            CGFloat(float3x3.columns.0.z),
            CGFloat(float3x3.columns.1.x),
            CGFloat(float3x3.columns.1.y),
            CGFloat(float3x3.columns.1.z),
            CGFloat(float3x3.columns.2.x),
            CGFloat(float3x3.columns.2.y),
            CGFloat(float3x3.columns.2.z)
        ]
        return CIVector(values: values, count: values.count)
    }
}
