//
//  GeometryExtension.swift
//  pixelstabilizer
//
//  Created by Hyojin Mo on 2017. 11. 2..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit
import Vision

extension CGRect {
    var minLength: CGFloat {
        return size.minLength
    }
    
    var maxLength: CGFloat {
        return size.maxLength
    }
}

extension CGSize {
    var minLength: CGFloat {
        return min(width, height)
    }
    
    var maxLength: CGFloat {
        return max(width, height)
    }
    
    var magnitude: CGSize {
        return CGSize(width: round(width.magnitude), height: round(height.magnitude))
    }
}

extension CGSize {
    static func aspectFit(aspectRatio: CGSize, boundingSize: CGSize) -> CGSize {
        let mW = boundingSize.width / aspectRatio.width;
        let mH = boundingSize.height / aspectRatio.height;
        
        var size = boundingSize
        if mH < mW {
            size.width = size.height / aspectRatio.height * aspectRatio.width
        }
        else if mW < mH {
            size.height = size.width / aspectRatio.width * aspectRatio.height
        }
        
        return size
    }
    
    static func aspectFill(aspectRatio :CGSize, boundingSize: CGSize) -> CGSize {
        let mW = boundingSize.width / aspectRatio.width;
        let mH = boundingSize.height / aspectRatio.height;
        
        var size = boundingSize
        if mH > mW {
            size.width = size.height / aspectRatio.height * aspectRatio.width
        }
        else if mW > mH {
            size.height = size.width / aspectRatio.width * aspectRatio.height
        }
        
        return size
    }
    
    func aspectFit(in boundingSize: CGSize) -> CGSize {
        return CGSize.aspectFit(aspectRatio: self, boundingSize: boundingSize)
    }
    
    func aspectFill(in boundingSize: CGSize) -> CGSize {
        return CGSize.aspectFill(aspectRatio: self, boundingSize: boundingSize)
    }
}

extension CGAffineTransform {
    var radians: CGFloat {
        return atan2(b, a)
    }
    
    var scaleX: CGFloat {
        return a
    }
    
    var scaleY: CGFloat {
        return d
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension CATransform3D {
    init(floatMatrix3x3: matrix_float3x3) {
        self.init()
        
        m11 = CGFloat(floatMatrix3x3.columns.0.x)
        m12 = CGFloat(floatMatrix3x3.columns.0.y)
        m13 = 0
        m14 = CGFloat(floatMatrix3x3.columns.0.z)
        
        m21 = CGFloat(floatMatrix3x3.columns.1.x)
        m22 = CGFloat(floatMatrix3x3.columns.1.y)
        m23 = 0
        m24 = CGFloat(floatMatrix3x3.columns.1.z)
        
        m31 = 0
        m32 = 0
        m33 = 1
        m34 = 0
        
        m41 = CGFloat(floatMatrix3x3.columns.2.x)
        m42 = CGFloat(floatMatrix3x3.columns.2.y)
        m43 = 0
        m44 = CGFloat(floatMatrix3x3.columns.2.z)
    }
}
