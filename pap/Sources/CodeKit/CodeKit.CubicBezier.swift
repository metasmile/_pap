//
//  CodeKit.CubicBezier.swift
//  pap
//
//  Created by HYOJIN MO on 17/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

struct CubicBezier {
    // http://www.paulwrightapps.com/blog/2014/9/4/finding-the-position-and-angle-of-points-along-a-bezier-curve-on-ios
    
    // cubic bezier control points
    private(set) var c0 = CGPoint.zero
    private(set) var c1 = CGPoint.zero
    private(set) var c2 = CGPoint.zero
    private(set) var c3 = CGPoint.zero
    
    // cubic bezier polynomial coefficients
    var p0: CGPoint {
        let x = c3.x - 3 * c2.x + 3 * c1.x - c0.x
        let y = c3.y - 3 * c2.y + 3 * c1.y - c0.y
        return CGPoint(x: x, y: y)
    }
    var p1: CGPoint {
        let x = 3 * c2.x - 6 * c1.x + 3 * c0.x
        let y = 3 * c2.y - 6 * c1.y + 3 * c0.y
        return CGPoint(x: x, y: y)
    }
    var p2: CGPoint {
        let x = 3 * c2.x - 6 * c1.x + 3 * c0.x
        let y = 3 * c2.y - 6 * c1.y + 3 * c0.y
        return CGPoint(x: x, y: y)
    }
    var p3: CGPoint {
        return c0
    }
    
    init(from c0: CGPoint, controlPoint1 c1: CGPoint, controlPoint2 c2: CGPoint, to c3: CGPoint) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
    }
    
    init(controlPoints c1: CGPoint, _ c2: CGPoint) {
        self.init(from: .zero, controlPoint1: c1, controlPoint2: c2, to: CGPoint(x: 1, y: 1))
    }
    
    init(controlPoints c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat) {
        self.init(controlPoints: CGPoint(x: c1x, y: c1y), CGPoint(x: c2x, y: c2y))
    }
    
    func x(at t: CGFloat) -> CGFloat {
        return ((p0.x * t + p1.x) * t + p2.x) * t + p3.x
    }
    
    func y(at t: CGFloat) -> CGFloat {
        return ((p0.y * t + p1.y) * t + p2.y) * t + p3.y
    }
    
    func point(at t: CGFloat) -> CGPoint {
        return CGPoint(x: x(at: t), y: y(at: t))
    }
    
    func angle(at t: CGFloat) -> CGFloat {
        let dxdt = 3 * p0.x * t * t + 2 * p1.x * t + p2.x
        let dydt = 3 * p0.y * t * t + 2 * p1.y * t + p2.y
        return atan2(dydt, dxdt)
    }
}

extension CubicBezier {
    var timingFunction: CAMediaTimingFunction {
        return CAMediaTimingFunction(controlPoints: Float(c1.x), Float(c1.y), Float(c2.x), Float(c2.y))
    }
}

extension CubicBezier {
    static let linear = CubicBezier(controlPoints: 0, 0, 1, 1)
    
    enum Sine {
        static let easeIn = CubicBezier(controlPoints: 0.47, 0, 0.745, 0.715)
        static let easeOut = CubicBezier(controlPoints: 0.39, 0.575, 0.565, 1)
        static let easeInOut = CubicBezier(controlPoints: 0.445, 0.05, 0.55, 0.95)
    }
    
    enum Quad {
        static let easeIn = CubicBezier(controlPoints: 0.55, 0.085, 0.68, 0.53)
        static let easeOut = CubicBezier(controlPoints: 0.25, 0.46, 0.45, 0.94)
        static let easeInOut = CubicBezier(controlPoints: 0.455, 0.03, 0.515, 0.955)
    }
    
    enum Cubic {
        static let easeIn = CubicBezier(controlPoints: 0.55, 0.055, 0.675, 0.19)
        static let easeOut = CubicBezier(controlPoints: 0.215, 0.61, 0.355, 1)
        static let easeInOut = CubicBezier(controlPoints: 0.645, 0.045, 0.355, 1)
    }
    
    enum Quart {
        static let easeIn = CubicBezier(controlPoints: 0.895, 0.03, 0.685, 0.22)
        static let easeOut = CubicBezier(controlPoints: 0.165, 0.84, 0.44, 1)
        static let easeInOut = CubicBezier(controlPoints: 0.77, 0, 0.175, 1)
    }
    
    enum Quint {
        static let easeIn = CubicBezier(controlPoints: 0.755, 0.05, 0.855, 0.06)
        static let easeOut = CubicBezier(controlPoints: 0.23, 1, 0.32, 1)
        static let easeInOut = CubicBezier(controlPoints: 0.86, 0, 0.07, 1)
    }
    
    enum Expo {
        static let easeIn = CubicBezier(controlPoints: 0.95, 0.05, 0.795, 0.035)
        static let easeOut = CubicBezier(controlPoints: 0.19, 1, 0.22, 1)
        static let easeInOut = CubicBezier(controlPoints: 1, 0, 0, 1)
    }
    
    enum Circ {
        static let easeIn = CubicBezier(controlPoints: 0.6, 0.04, 0.98, 0.335)
        static let easeOut = CubicBezier(controlPoints: 0.075, 0.82, 0.165, 1)
        static let easeInOut = CubicBezier(controlPoints: 0.785, 0.135, 0.15, 0.86)
    }
    
    enum Back {
        static let easeIn = CubicBezier(controlPoints: 0.6, -0.28, 0.735, 0.045)
        static let easeOut = CubicBezier(controlPoints: 0.175, 0.885, 0.32, 1.275)
        static let easeInOut = CubicBezier(controlPoints: 0.68, -0.55, 0.265, 1.55)
    }
}

extension CubicBezier {
    func value(_ value: Float, in range: ClosedRange<Float>, with base: Float) -> Float {
        let min: Float = 0
        let d = base - range.lowerBound
        let max = range.upperBound - range.lowerBound
        let v = value - range.lowerBound
        let t: Float
        
        if base != range.lowerBound, base != range.upperBound, value < base {
            t = 1 - ((v - min) / (d - min)).magnitude
        }
        else {
            if base < range.upperBound {
                t = ((v - d) / (max - d)).magnitude
            }
            else {
                t = (v / max).magnitude
            }
        }
        
        let ratio = Float(self.y(at: CGFloat(t)) / self.y(at: 1))
        let base = base < range.upperBound ? d : min
        let offsetX = base + (v - base) * ratio
        
        return Float(offsetX) + range.lowerBound
    }
}
