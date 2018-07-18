//
//  CodeKit.CoreGraphics.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 9. 19..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

extension Array where Element==CGRect{
    func union() -> CGRect?{
        return self[1...].reduce(first, { $0?.union($1) })
    }

    func biggest() -> CGRect{
        return self.sorted { (rect: CGRect, rect2: CGRect) -> Bool in
            return rect.width*rect.height > rect2.width*rect2.height
        }.first ?? CGRect.null
    }
}

extension CGRect {
    var minLength: CGFloat {
        return size.minLength
    }
    
    var maxLength: CGFloat {
        return size.maxLength
    }

    func normalized(by size:CGSize) -> CGRect{
        return CGRect(
                x:normalize(origin.x, 0, size.width)
                ,y:normalize(origin.y, 0, size.height)
                ,width:normalize(size.width, 0, size.width)
                ,height: normalize(size.width, 0, size.height)
        )
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

    var area: CGFloat {
        return width*height
    }

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

//Hashable
extension CGAffineTransform: Hashable {
    public var hashValue: Int {
        return String(describing: self).hashValue
    }
}
extension CGPoint: Hashable {
    public var hashValue: Int {
        return String(describing: self).hashValue
    }
}
extension CGSize: Hashable {
    public var hashValue: Int {
        return String(describing: self).hashValue
    }
}
extension CGRect: Hashable {
    public var hashValue: Int {
        return String(describing: self).hashValue
    }
}

