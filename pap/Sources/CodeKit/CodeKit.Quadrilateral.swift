//
//  CodeKit.Quadrilateral.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 10. 8..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

public struct CGQuad {
    // CLOCKWISE from Top Left
    var corners: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
    
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
    
    init(_ topLeft: CGPoint, _ topRight: CGPoint, _ bottomRight: CGPoint, _ bottomLeft: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }
    
    init(_ corners: [CGPoint], clockwised: Bool = true) {
        let corners: [CGPoint] = corners.count == 4 ? corners : Array<CGPoint>(repeating: .zero, count: 4)
        
        if clockwised {
            self.init(corners[0], corners[1], corners[2], corners[3])
        }
        else {
            self.init(corners[0], corners[3], corners[2], corners[1])
        }
    }
}

extension CGQuad {
    var boundingRect: CGRect {
        let xValues = corners.map { $0.x }
        let yValues = corners.map { $0.y }
        
        guard
            let xMin = xValues.min(),
            let xMax = xValues.max(),
            let yMin = yValues.min(),
            let yMax = yValues.max()
            else { return .zero }
        
        return CGRect(x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin)
    }
}

extension CGQuad {
    func inset(by insets: UIEdgeInsets) -> CGQuad {
        var quad = self
        
        quad.topLeft.x += insets.left
        quad.topLeft.y += insets.top
        
        quad.topRight.x -= insets.right
        quad.topRight.y += insets.top
        
        quad.bottomRight.x -= insets.right
        quad.bottomRight.y -= insets.bottom
        
        quad.bottomLeft.x += insets.left
        quad.bottomLeft.y -= insets.bottom
        
        return quad
    }
}

extension CGRect {
    func perspectiveTransform(to quad: CGQuad) -> CATransform3D {
        return CATransform3D(from: self, to: quad)
    }
}

extension CATransform3D {
    init(from rect: CGRect, to quad: CGQuad) {
        // https://github.com/agens-no/AGGeometryKit/blob/master/AGGeometryKit/AGKQuad.m
        let X = rect.origin.x
        let Y = rect.origin.y
        let W = rect.size.width
        let H = rect.size.height
        
        let x1a = quad.topLeft.x
        let y1a = quad.topLeft.y
        let x2a = quad.topRight.x
        let y2a = quad.topRight.y
        let x3a = quad.bottomLeft.x
        let y3a = quad.bottomLeft.y
        let x4a = quad.bottomRight.x
        let y4a = quad.bottomRight.y
        
        let y21 = y2a - y1a
        let y32 = y3a - y2a
        let y43 = y4a - y3a
        let y14 = y1a - y4a
        let y31 = y3a - y1a
        let y42 = y4a - y2a
        
        let a = -H*(x2a*x3a*y14 + x2a*x4a*y31 - x1a*x4a*y32 + x1a*x3a*y42)
        let b = W*(x2a*x3a*y14 + x3a*x4a*y21 + x1a*x4a*y32 + x1a*x2a*y43)
//        let c = H*X*(x2a*x3a*y14 + x2a*x4a*y31 - x1a*x4a*y32 + x1a*x3a*y42) - H*W*x1a*(x4a*y32 - x3a*y42 + x2a*y43) - W*Y*(x2a*x3a*y14 + x3a*x4a*y21 + x1a*x4a*y32 + x1a*x2a*y43)
        let c0 = -H*W*x1a*(x4a*y32 - x3a*y42 + x2a*y43)
        let cx = H*X*(x2a*x3a*y14 + x2a*x4a*y31 - x1a*x4a*y32 + x1a*x3a*y42)
        let cy = -W*Y*(x2a*x3a*y14 + x3a*x4a*y21 + x1a*x4a*y32 + x1a*x2a*y43)
        let c = c0 + cx + cy
        
        let d = H*(-x4a*y21*y3a + x2a*y1a*y43 - x1a*y2a*y43 - x3a*y1a*y4a + x3a*y2a*y4a)
        let e = W*(x4a*y2a*y31 - x3a*y1a*y42 - x2a*y31*y4a + x1a*y3a*y42)
//        let f = -(W*(x4a*(Y*y2a*y31 + H*y1a*y32) - x3a*(H + Y)*y1a*y42 + H*x2a*y1a*y43 + x2a*Y*(y1a - y3a)*y4a + x1a*Y*y3a*(-y2a + y4a)) - H*X*(x4a*y21*y3a - x2a*y1a*y43 + x3a*(y1a - y2a)*y4a + x1a*y2a*(-y3a + y4a)))
        let f0 = -W*H*(x4a*y1a*y32 - x3a*y1a*y42 + x2a*y1a*y43)
        let fx = H*X*(x4a*y21*y3a - x2a*y1a*y43 - x3a*y21*y4a + x1a*y2a*y43)
        let fy = -W*Y*(x4a*y2a*y31 - x3a*y1a*y42 - x2a*y31*y4a + x1a*y3a*y42)
        let f = f0 + fx + fy
        
        let g = H*(x3a*y21 - x4a*y21 + (-x1a + x2a)*y43)
        let h = W*(-x2a*y31 + x4a*y31 + (x1a - x3a)*y42)
//        var i = W*Y*(x2a*y31 - x4a*y31 - x1a*y42 + x3a*y42) + H*(X*(-(x3a*y21) + x4a*y21 + x1a*y43 - x2a*y43) + W*(-(x3a*y2a) + x4a*y2a + x2a*y3a - x4a*y3a - x2a*y4a + x3a*y4a))
        let i0 = H*W*(x3a*y42 - x4a*y32 - x2a*y43)
        let ix = H*X*(x4a*y21 - x3a*y21 + x1a*y43 - x2a*y43)
        let iy = W*Y*(x2a*y31 - x4a*y31 - x1a*y42 + x3a*y42)
        var i = i0 + ix + iy
        
        let kEpsilon: CGFloat = 0.0001
        
        if (abs(i) < kEpsilon) {
            i = kEpsilon * (i > 0 ? 1.0 : -1.0)
        }
        
        self.init(m11: a/i, m12: d/i, m13: 0, m14: g/i,
                  m21: b/i, m22: e/i, m23: 0, m24: h/i,
                  m31: 0, m32: 0, m33: 1, m34: 0,
                  m41: c/i, m42: f/i, m43: 0, m44: 1.0)
    }
}
