//
//  CodeKit.CIFilter.swift
//  pap
//
//  Created by HYOJIN MO on 17/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

class CIFilterGroup<Filter: CIFilter>: CIFilter {
    fileprivate(set) var filters: [Filter] = [Filter]()
    
    required init(filters: [Filter]? = nil) {
        super.init()
        
        self.filters.append(contentsOf: filters ?? [])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = type(of: self).init(filters: filters.copyElements())
        return copy
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        
        guard var image = inputImage else { return nil }
        
        for filter in filters {
            autoreleasepool {
                filter.setValue(image, forKey: kCIInputImageKey)
                if let result = filter.outputImage {
                    image = result
                }
            }
        }
        
        return image
    }
}

class CIFilterAttributeItem: Codable, NSCopying {
    var attributeKey: String
    var name: String
    var value: Float
    var defaultValue: Float
    var minimumValue: Float
    var maximumValue: Float
    var offset: Int
    var isIntensity: Bool
    var canEdit: Bool = true
    
    var hasChanges: Bool {
        return defaultValue != value
    }
    
    init(name: String, attributeKey: String, defaultValue: Float?, minimumValue: Float? = nil, maximumValue: Float? = nil, offset: Int = 0, isIntensity: Bool = true, canEdit: Bool = true) {
        self.name = name
        self.attributeKey = attributeKey
        self.defaultValue = defaultValue ?? 0
        self.minimumValue = minimumValue ?? 0
        self.maximumValue = maximumValue ?? 1
        self.offset = offset
        self.isIntensity = isIntensity
        self.canEdit = canEdit
        
        self.value = defaultValue ?? 0
    }
    
    convenience init(name: String, attributeKey: String, boolValue: Bool) {
        self.init(name: name, attributeKey: attributeKey, defaultValue: boolValue ? 1.0 : 0.0)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = CIFilterAttributeItem(name: name, attributeKey: attributeKey, defaultValue: defaultValue, minimumValue: minimumValue, maximumValue: maximumValue, offset: offset, isIntensity: isIntensity)
        copy.value = value
        return copy
    }
}

extension CIFilterAttributeItem {
    func bezierValue(_ bezier: CubicBezier = CubicBezier.Cubic.easeOut) -> Float {
        return bezier.value(value, in: minimumValue...maximumValue, with: defaultValue)
    }
}

extension CIFilterAttributeItem: Equatable {
    static func == (lhs: CIFilterAttributeItem, rhs: CIFilterAttributeItem) -> Bool {
        return lhs.name == rhs.name && lhs.value == rhs.value
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
        return attributeItem.value
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
        let copy = CIFilterAttributes(name: name, key: key, attributeType: attributeType ?? "", attributes: attributeItems.copyElements())
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
        
        let defaultValue = attributes[kCIAttributeDefault]
        
        if attributeType == kCIAttributeTypeScalar {
            attributeItems = [CIFilterAttributeItem(name: name, attributeKey: key, defaultValue: defaultValue as? Float, minimumValue: minimumValue, maximumValue: maximumValue)]
        }
        else if attributeType == kCIAttributeTypeOffset {
            let defaultVector = defaultValue as? CIVector
            
            attributeItems = [
                CIFilterAttributeItem(name: "\(name).x", attributeKey: key, defaultValue: Float(defaultVector?.x ?? 0), minimumValue: minimumValue, maximumValue: maximumValue),
                CIFilterAttributeItem(name: "\(name).y", attributeKey: key, defaultValue: Float(defaultVector?.y ?? 0), minimumValue: minimumValue, maximumValue: maximumValue)
            ]
        }
    }
    
    func setAttributeItems(_ attributeItems: [CIFilterAttributeItem]) {
        self.attributeItems = attributeItems
    }
    
    func setAttributeItem(_ attributeItem: CIFilterAttributeItem, at offset: Int = 0) {
        self.attributeItems[offset] = attributeItem
    }
}

extension CIFilterAttributes: Equatable {
    public static func == (lhs: CIFilterAttributes, rhs: CIFilterAttributes) -> Bool {
        return lhs.name == rhs.name && lhs.key == rhs.key && lhs.attributeItems.elementsEqual(rhs.attributeItems)
    }
}

class CIBuiltInFilter: CIFilter, Codable {
    var filterAttributes = [String: CIFilterAttributes]()
    private var builtInFilter: CIFilter?
    private(set) var editableItems: [CIFilterAttributeItem]?
    
    var filter: CIFilter {
        return builtInFilter ?? self
    }
    
    required init(name: String, editableItems attributeItems: [CIFilterAttributeItem] = []) {
        super.init()
        
        self.name = name
        self.builtInFilter = CIFilter(name: name)
        self.editableItems = attributeItems
        
        self.filterAttributes = [:]
        for attributeItem in attributeItems {
            let attributes = CIFilterAttributes(name: attributeItem.name, key: attributeItem.attributeKey)
            attributes.setDefaults(with: filter, name: attributeItem.name, sliderRange: attributeItem.minimumValue...attributeItem.maximumValue)
            attributes.setAttributeItem(attributeItem, at: attributeItem.offset)
            filterAttributes[attributeItem.attributeKey] = attributes
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private enum CodingKeys: Int, CodingKey {
        case filterName
        case editableItems
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let filterName = try container.decode(String.self, forKey: .filterName)
        let editableItems = try container.decode([CIFilterAttributeItem].self, forKey: .editableItems)
        
        self.init(name: filterName, editableItems: editableItems)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .filterName)
        try container.encode(self.editableItems, forKey: .editableItems)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = type(of: self).init(name: self.name, editableItems: editableItems?.copyElements() ?? [])
        return copy
    }

    var hasChanges: Bool {
        return filterAttributes.values.reduce(false) { $0 || $1.hasChanges }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return (name == (object as? CIFilter)?.name) == true
    }
    
    private func filterAttribute(with key: String) -> CIFilterAttributes? {
        return filterAttributes[key]
    }
    
    func setFilterAttribute(_ value: Float, with key: String, at index: Int) {
        filterAttribute(with: key)?.setAttributes(value: value, at: index)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        return autoreleasepool { () -> CIImage? in
            guard let image = inputImage else { return nil }
            filter.setValue(image, forKey: kCIInputImageKey)
            filterAttributes.forEach { filter.setValue($0.value.value, forKey: $0.value.key) }
            return filter.outputImage
        }
    }
}

extension CIBuiltInFilter {
    public static func == (lhs: CIBuiltInFilter, rhs: CIBuiltInFilter) -> Bool {
        return lhs.name == rhs.name && lhs.editableItems?.elementsEqual(rhs.editableItems ?? []) == true
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
