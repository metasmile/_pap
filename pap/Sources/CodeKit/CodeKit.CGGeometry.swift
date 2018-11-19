//
//  Geometry.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 12..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return lhs.applying(CGAffineTransform(scaleX: rhs, y: rhs))
    }
    
    func ceiled() -> CGSize {
        return CGSize(width: ceil(width), height: ceil(height))
    }
    
    func floored() -> CGSize {
        return CGSize(width: floor(width), height: floor(height))
    }
}

extension CGPoint {
    static func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }
    
    func distance(to point: CGPoint) -> CGFloat {
        return CGPoint.distance(from: self, to: point)
    }
}
