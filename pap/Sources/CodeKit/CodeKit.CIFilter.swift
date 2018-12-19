//
//  CodeKit.CIFilter.swift
//  pap
//
//  Created by HYOJIN MO on 17/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

class CIFilterAttributeItem {
    var name: String
    var value: Float = 0
    var defaultValue: Float = 0
    var minimumValue: Float = 0
    var maximumValue: Float = 1
    var offset: Int = 0
    var isIntensity: Bool = true
    
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
}

public class CIFilterAttributes {
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
        return attributes(at: 0)?.value ?? 0
    }
    var offset: CGPoint {
        return CGPoint(x: CGFloat(attributes(at: 0)?.value ?? 0), y: CGFloat(attributes(at: 1)?.value ?? 0))
    }
    
    private(set) var attributeItems: [CIFilterAttributeItem] = [CIFilterAttributeItem]()
    
    func attributes(at offsetIndex: Int) -> CIFilterAttributeItem? {
        return attributeItems[safe: offsetIndex]
    }
    
    func setAttributes(value: Float, at offsetIndex: Int = 0) {
        attributeItems[safe: offsetIndex]?.value = value
    }
    
    private(set) var attributeType: String?
    
    init(key: String) {
        self.key = key
    }
    
    convenience init(key: String, attributeType: String, attributes: [CIFilterAttributeItem]) {
        self.init(key: key)
        
        self.attributeType = attributeType
        self.attributeItems = attributes
    }
    
    func setDefaults(with filter: CIFilter?, name: String?) {
        guard let name = name, let attributes = filter?.attributes[key] as? [String: Any] else { return }
        
        attributeType = attributes[kCIAttributeType] as? String
        
        if attributeType == kCIAttributeTypeScalar {
            switch filter?.name {
            case "CISepiaTone"?:
                attributeItems = [CIFilterAttributeItem(name: name, defaultValue: 0, minimumValue: attributes[kCIAttributeSliderMin] as? Float, maximumValue: attributes[kCIAttributeSliderMax] as? Float)]
            default:
                attributeItems = [CIFilterAttributeItem(name: name, defaultValue: attributes[kCIAttributeDefault] as? Float, minimumValue: attributes[kCIAttributeSliderMin] as? Float, maximumValue: attributes[kCIAttributeSliderMax] as? Float)]
            }
        }
        else if attributeType == kCIAttributeTypeOffset {
            switch filter?.name {
            case "CITemperatureAndTint"?:
                attributeItems = [
                    CIFilterAttributeItem(name: "Temparature", defaultValue: 6500, minimumValue: 2000, maximumValue: 10000),
                    CIFilterAttributeItem(name: "Tint", defaultValue: 0, minimumValue: -200, maximumValue: 200)
                ]
            default: break
            }
        }
    }
}
