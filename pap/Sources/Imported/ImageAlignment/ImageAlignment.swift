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

// [!] README
/*
    cikernel metal 빌드에 추가하기
    https://developer.apple.com/documentation/coreimage/cikernel/2880194-init
*/

import UIKit
import Vision

public class ImageAlignment {
    static let sharedCIContext = CIContext.shared
    
    public struct StabilizationMode: OptionSet, Hashable {
        public let rawValue: Int
        
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
    public func stabilize(with image: UIImage, mode: ImageAlignment.StabilizationMode = .translation) -> UIImage {
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
    public func stabilizeHomographic(with image: UIImage, crop: Bool) -> UIImage {
        guard let matrix = ImageAlignment.homographicTransform(image, onto: self) else { return self }
        guard let warppedImage = self.asCIImage?.applyHomographic(matrix, crop: crop), let cgimage = ImageAlignment.sharedCIContext.createCGImage(warppedImage, from: warppedImage.extent) else { return self }
        return UIImage(cgImage: cgimage)
    }

    @objc
    public func stabilizeTranslation(with image: UIImage, crop: Bool) -> UIImage {
        guard let transform = ImageAlignment.translationTransform(image, onto: self) else { return self }
        guard let transformedImage = self.asCIImage?.applyTranslation(transform, crop: crop), let cgimage = ImageAlignment.sharedCIContext.createCGImage(transformedImage, from: transformedImage.extent) else { return self }
        return UIImage(cgImage: cgimage)
    }
}

@available(iOS 11.0, *)
public extension CIImage {
    public func stabilize(with image: CIImage, mode: ImageAlignment.StabilizationMode) -> CIImage {
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
    public func stabilizeHomographic(with image: CIImage, crop: Bool) -> CIImage {
        guard let matrix = ImageAlignment.homographicTransform(image, onto: self) else { return self }
        guard let warppedImage = self.applyHomographic(matrix, crop: crop) else { return self }
        return warppedImage
    }
    
    @objc
    public func stabilizeTranslation(with image: CIImage, crop: Bool) -> CIImage {
        guard let transform = ImageAlignment.translationTransform(image, onto: self) else { return self }
        guard let transformedImage = self.applyTranslation(transform, crop: crop) else { return self }
        return transformedImage
    }
}

@available(iOS 11.0, *)
extension ImageAlignment {
    static func homographicTransform(_ floating: UIImage, onto reference: UIImage) -> matrix_float3x3? {
        guard let floatingImage = floating.asCIImage, let referenceImage = reference.asCIImage else { return nil }
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
    static func translationTransform(_ floating: UIImage, onto reference: UIImage) -> CGAffineTransform? {
        guard let floatingImage = floating.asCIImage, let referenceImage = reference.asCIImage else { return nil }
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

private struct Kernels {
    static let translation: CIWarpKernel? = {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else { return nil }
        return try? CIWarpKernel(functionName: "warpTranslation", fromMetalLibraryData: data)
    }()
    
    static let homographic: CIWarpKernel? = {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else { return nil }
        return try? CIWarpKernel(functionName: "warpHomographic", fromMetalLibraryData: data)
    }()
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
    
    func applyHomographic(_ matrix: matrix_float3x3, crop: Bool) -> CIImage? {
        let clamp: CGPoint = crop ? CGPoint(x: extent.width / 20, y: extent.height / 20) : .zero
        let croppedRect = extent.insetBy(dx: clamp.x / 2, dy: clamp.y / 2)
        
        var value = WarpMatrix(matrix: matrix, size: float2(Float(extent.width), Float(extent.height)), clampRange: float2(x: Float(clamp.x), y: Float(clamp.y)))
        
        var uniformValues = [MTLBuffer]()
        if let buffer = MTLContext.shared.device.makeBuffer(bytes: &value, length: MemoryLayout<WarpMatrix>.size(ofValue: value), options: MTLResourceOptions.cpuCacheModeWriteCombined) {
            uniformValues.append(buffer)
        }
        
        return self.applyMetalShader(vetexFunction: "warpHomographic", uniformValues: uniformValues)?.cropped(to: croppedRect).clamped(to: extent).oriented(.downMirrored)
    }
    
    func applyTranslation(_ translation: CGAffineTransform, crop: Bool) -> CIImage? {
        let clamp: CGPoint = crop ? CGPoint(x: extent.width / 20, y: extent.height / 20) : .zero
        let croppedRect = extent.insetBy(dx: clamp.x / 2, dy: clamp.y / 2)
        
        var value = WarpMatrix(translation: float2(x: Float(translation.tx / extent.width), y: Float(translation.ty / extent.height)), size: float2(Float(extent.width), Float(extent.height)), clampRange: float2(x: Float(clamp.x), y: Float(clamp.y)))
        
        var uniformValues = [MTLBuffer]()
        if let buffer = MTLContext.shared.device.makeBuffer(bytes: &value, length: MemoryLayout<WarpMatrix>.size(ofValue: value), options: MTLResourceOptions.cpuCacheModeWriteCombined) {
            uniformValues.append(buffer)
        }
        
        return self.applyMetalShader(vetexFunction: "warpTranslation", uniformValues: uniformValues)?.cropped(to: croppedRect).clamped(to: extent).oriented(.downMirrored)
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
