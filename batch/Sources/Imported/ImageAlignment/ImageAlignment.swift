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

class ImageAlignment {
    static let sharedCIContext = CIContext()
}

@available(iOS 11.0, *)
public extension UIImage {
    public enum StabilizationMode {
        case homographic
        case translation
    }

    public func stabilize(with image: UIImage, mode: StabilizationMode = .homographic) -> UIImage {
        switch mode {
        case .homographic:
            return stabilizeHomographic(with: image)
        case .translation:
            return stabilizeTranslation(with: image)
        }
    }

    @objc
    public func stabilizeHomographic(with image: UIImage) -> UIImage {
        guard let matrix = ImageAlignment.homographicTransform(image, onto: self) else { return self }
        guard let warppedImage = CIImage(image: self)?.applyWarp(matrix: matrix), let cgimage = ImageAlignment.sharedCIContext.createCGImage(warppedImage, from: warppedImage.extent) else { return self }
        return UIImage(cgImage: cgimage)
    }

    @objc
    public func stabilizeTranslation(with image: UIImage) -> UIImage {
        guard let transform = ImageAlignment.translationTransform(image, onto: self) else { return self }
        guard let transformedImage = CIImage(image: self)?.applyTranslation(CGPoint(x: transform.tx, y: transform.ty)), let cgimage = ImageAlignment.sharedCIContext.createCGImage(transformedImage, from: transformedImage.extent) else { return self }
        return UIImage(cgImage: cgimage)
    }
}

@available(iOS 11.0, *)
extension ImageAlignment {
    static func homographicTransform(_ floating: UIImage, onto reference: UIImage) -> matrix_float3x3? {
        guard let floatingImage = CIImage(image: floating), let referenceImage = CIImage(image: reference) else { return nil }
        let request = VNHomographicImageRegistrationRequest(targetedCIImage: floatingImage)
        let requestHandler = VNImageRequestHandler(ciImage: referenceImage)
        
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
        guard let floatingImage = CIImage(image: floating), let referenceImage = CIImage(image: reference) else { return nil }
        let request = VNTranslationalImageRegistrationRequest(targetedCIImage: floatingImage)
        let requestHandler = VNImageRequestHandler(ciImage: referenceImage)
        
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
    func applyWarp(matrix: matrix_float3x3) -> CIImage? {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else { return nil }
        
        let kernel = try? CIWarpKernel(functionName: "warpHomography", fromMetalLibraryData: data)
        return kernel?.apply(extent: extent, roiCallback: { index, rect in
            return rect
        }, image: self, arguments: [
            CIVector(float3x3: matrix)
        ])
    }
    
    func applyTranslation(_ translation: CGPoint) -> CIImage? {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else { return nil }
        
        let kernel = try? CIWarpKernel(functionName: "translate", fromMetalLibraryData: data)
        return kernel?.apply(extent: extent, roiCallback: { index, rect in
            return rect
        }, image: self, arguments: [
            CIVector(cgPoint: translation)
        ])
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
            CGFloat(float3x3.columns.2.z),
        ]
        return CIVector(values: values, count: values.count)
    }
}
