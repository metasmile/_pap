//
//  CodeKit.CIFilter.swift
//  pap
//
//  Created by HYOJIN MO on 17/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

class CIFilterAttributeItem: Codable, NSCopying {
    var name: String
    var value: Float
    var defaultValue: Float
    var minimumValue: Float
    var maximumValue: Float
    var offset: Int
    var isIntensity: Bool
    
    var hasChanges: Bool {
        return defaultValue != value
    }
    
    init(name: String, defaultValue: Float?, minimumValue: Float? = nil, maximumValue: Float? = nil, offset: Int = 0, isIntensity: Bool = true) {
        self.name = name
        self.defaultValue = defaultValue ?? 0
        self.minimumValue = minimumValue ?? 0
        self.maximumValue = maximumValue ?? 1
        self.offset = offset
        self.isIntensity = isIntensity
        
        self.value = defaultValue ?? 0
    }
    
    convenience init(name: String, boolValue: Bool) {
        self.init(name: name, defaultValue: boolValue ? 1.0 : 0.0)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = CIFilterAttributeItem(name: name, defaultValue: defaultValue, minimumValue: minimumValue, maximumValue: maximumValue, offset: offset, isIntensity: isIntensity)
        copy.value = value
        return copy
    }
}

extension CIFilterAttributeItem {
    func bezierValue(_ bezier: CubicBezier = CubicBezier.Cubic.easeOut) -> Float {
        return bezier.value(value, in: minimumValue...maximumValue, with: defaultValue)
    }
}

public class CIFilterAttributes: Codable, NSCopying {
    var name: String
    var key: String
    var value: Any {
        switch attributeType {
        case kCIAttributeTypeScalar?: return number
        case kCIAttributeTypeOffset?: return CIVector(cgPoint: offset)
        case kCIAttributeTypePosition?: return CIVector(cgPoint: offset)
        case kCIAttributeTypeBoolean?: return Bool(truncating: NSNumber(value: number))
        default: return number
        }
    }
    var number: Float {
        guard let attributeItem = attributes(at: 0) else { return 0 }
        return attributeItem.isIntensity ? attributeItem.bezierValue() : attributeItem.value
    }
    var offset: CGPoint {
        return CGPoint(x: CGFloat(attributes(at: 0)?.value ?? 0), y: CGFloat(attributes(at: 1)?.value ?? 0))
    }
    
    var hasChanges: Bool {
        return attributeItems.reduce(false) { $0 || $1.hasChanges }
    }
    
    private(set) var attributeItems: [CIFilterAttributeItem]
    
    func attributes(at offsetIndex: Int) -> CIFilterAttributeItem? {
        return attributeItems[safe: offsetIndex]
    }
    
    func setAttributes(value: Float, at offsetIndex: Int = 0) {
        attributeItems[safe: offsetIndex]?.value = value
    }
    
    private(set) var attributeType: String?
    
    init(name: String, key: String) {
        self.name = name
        self.key = key
        self.attributeItems = [CIFilterAttributeItem]()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = CIFilterAttributes(name: name, key: key, attributeType: attributeType ?? "", attributes: attributeItems.compactMap({ $0.copy() as? CIFilterAttributeItem }))
        return copy
    }
    
    convenience init(key: String) {
        self.init(name: key, key: key)
    }
    
    convenience init(key: String, attributeType: String, attributes: [CIFilterAttributeItem]) {
        self.init(name: key, key: key, attributeType: attributeType, attributes: attributes)
    }
    
    convenience init(name: String, key: String, attributeType: String, attributes: [CIFilterAttributeItem]) {
        self.init(name: name, key: key)
        
        self.attributeType = attributeType
        self.attributeItems = attributes
    }
    
    func setDefaults(with filter: CIFilter?, name: String?, sliderRange: ClosedRange<Float>? = nil, attributeIndex: Int = 0) {
        guard let name = name, let attributes = filter?.attributes[key] as? [String: Any] else { return }
        
        attributeType = attributes[kCIAttributeType] as? String
        
        let minimumValue = sliderRange?.lowerBound ?? attributes[kCIAttributeSliderMin] as? Float
        let maximumValue = sliderRange?.upperBound ?? attributes[kCIAttributeSliderMax] as? Float
        
        if attributeType == kCIAttributeTypeScalar {
            switch filter?.name {
            case "CISepiaTone"?:
                attributeItems = [CIFilterAttributeItem(name: name, defaultValue: 0, minimumValue: minimumValue, maximumValue: maximumValue)]
            default:
                attributeItems = [CIFilterAttributeItem(name: name, defaultValue: attributes[kCIAttributeDefault] as? Float, minimumValue: minimumValue, maximumValue: maximumValue)]
            }
        }
        else if attributeType == kCIAttributeTypeOffset {
            switch filter?.name {
            case "CITemperatureAndTint"?:
                attributeItems = [
                    CIFilterAttributeItem(name: "Temparature", defaultValue: 6500, minimumValue: minimumValue ?? 2000, maximumValue: maximumValue ?? 10000),
                    CIFilterAttributeItem(name: "Tint", defaultValue: 0, minimumValue: minimumValue ?? -150, maximumValue: maximumValue ?? 150)
                ]
            default: break
            }
        }
    }
}

// https://github.com/muukii/ColorCube/blob/master/ColorCube/ColorCube.swift
public class CIColorCube: CIFilter {
    private var lutImage: UIImage?
    private var dimension: Int = 64
    
    convenience init(lut image: UIImage?, dimension: Int = 64) {
        self.init()
        
        self.lutImage = image
        self.dimension = dimension
    }
    
    @objc dynamic var inputImage: CIImage?
    
    public override var outputImage: CIImage? {
        return autoreleasepool { () -> CIImage? in
            guard let inputImage = inputImage, let lutImage = lutImage, let cubeData = CIColorCube.cubeData(lutImage: lutImage, dimension: dimension, colorSpace: inputImage.defaultColorSpace) else { return nil }
            let filter = CIFilter(name: "CIColorCube", parameters: [
                kCIInputImageKey: inputImage,
                "inputCubeData": cubeData,
                "inputCubeDimension": dimension
            ])
            return filter?.outputImage
        }
    }
    
    private static func createBitmap(image: CGImage, colorSpace: CGColorSpace) -> UnsafeMutablePointer<UInt8>? {
        let width = image.width
        let height = image.height
        
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        
        let bitmapSize = bytesPerRow * height
        
        guard let data = malloc(bitmapSize) else {
            return nil
        }
        
        guard let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
            releaseCallback: nil,
            releaseInfo: nil) else {
                return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return data.bindMemory(to: UInt8.self, capacity: bitmapSize)
    }
    
    private static func cubeData(lutImage: UIImage, dimension: Int, colorSpace: CGColorSpace) -> Data? {
        
        guard let cgImage = lutImage.cgImage else {
            return nil
        }
        
        guard let bitmap = createBitmap(image: cgImage, colorSpace: colorSpace) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let rowNum = width / dimension
        let columnNum = height / dimension
        
        let dataSize = dimension * dimension * dimension * MemoryLayout<Float>.size * 4
        
        var array = [Float](repeating: 0, count: dataSize)
        
        var bitmapOffest: Int = 0
        var z: Int = 0
        
        for _ in stride(from: 0, to: rowNum, by: 1) {
            for y in stride(from: 0, to: dimension, by: 1) {
                let tmp = z
                for _ in stride(from: 0, to: columnNum, by: 1) {
                    for x in stride(from: 0, to: dimension, by: 1) {
                        
                        let dataOffset = (z * dimension * dimension + y * dimension + x) * 4
                        
                        let position = bitmap
                            .advanced(by: bitmapOffest)
                        
                        array[dataOffset + 0] = Float(position
                            .advanced(by: 0)
                            .pointee) / 255
                        
                        array[dataOffset + 1] = Float(position
                            .advanced(by: 1)
                            .pointee) / 255
                        
                        array[dataOffset + 2] = Float(position
                            .advanced(by: 2)
                            .pointee) / 255
                        
                        array[dataOffset + 3] = Float(position
                            .advanced(by: 3)
                            .pointee) / 255
                        
                        bitmapOffest += 4
                        
                    }
                    z += 1
                }
                z = tmp
            }
            z += columnNum
        }
        
        free(bitmap)
        
        return array.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}
