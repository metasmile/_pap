//
// Created by BLACKGENE on 30/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import CoreGraphics

public typealias NumericBinaryFloatingPoint = SignedNumeric & FloatingPoint

extension Double {
    /// Rounds the double to decimal places value
    func round(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    public func roundedString(toPlaces places:Int, trimTrailingZeros:Bool=false) -> String{
        let dayStr = String(round(toPlaces: 1))
        if trimTrailingZeros{
            let repeatingZero = "."+String(repeating: "0", count: places)
            return dayStr.hasSuffix(repeatingZero) ? dayStr.remove(repeatingZero) : dayStr
        }
        return dayStr
    }
}

public func clamp<T>(_ value: T, _ minValue: T, _ maxValue: T) -> T where T:Comparable {
    return min(max(value, minValue), maxValue)
}

public func interpolate<T>(_ startValue: T, _ endValue:T, _ progress:T) -> T where T : NumericBinaryFloatingPoint {
    return startValue + ((endValue - startValue) * progress)
}

public func normalize<T>(_ value:T, _ startValue:T, _ endValue:T) -> T where T : NumericBinaryFloatingPoint {
    let diff = endValue - startValue
    return diff == 0 ? 0 : (value - startValue) / diff
}

public func remap<T>(_ value: T, _ oldStartValue: T, _ oldEndValue: T, _ newStartValue: T, _ newEndValue: T) -> T where T : NumericBinaryFloatingPoint {
    return interpolate(newStartValue, newEndValue, normalize(value, oldStartValue, oldEndValue))
}

public func remapClamp<T>(_ value: T, _ oldStartValue: T, _ oldEndValue: T, _ newStartValue: T, _ newEndValue: T) -> T where T : NumericBinaryFloatingPoint {
    return clamp(remap(value,oldStartValue,oldEndValue,newStartValue,newEndValue), newStartValue, newEndValue)
}

public func remapNormalizeClamp<T>(_ value: T, _ oldStartValue: T, _ oldEndValue: T) -> T where T : NumericBinaryFloatingPoint {
    return clamp(normalize(value, oldStartValue, oldEndValue), 0, 1)
}


public func interpolate(_ startValue: CGFloat, _ endValue:CGFloat, _ progress:CGFloat) -> CGFloat  {
    return startValue + ((endValue - startValue) * progress)
}

public func normalize(_ value:CGFloat, _ startValue:CGFloat, _ endValue:CGFloat) -> CGFloat  {
    return CGFloat(normalize(Float(value), Float(startValue), Float(endValue)))
}

public func remap(_ value: CGFloat, _ oldStartValue: CGFloat, _ oldEndValue: CGFloat, _ newStartValue: CGFloat, _ newEndValue: CGFloat) -> CGFloat  {
    return interpolate(newStartValue, newEndValue, normalize(value, oldStartValue, oldEndValue))
}

public func remapClamp(_ value: CGFloat, _ oldStartValue: CGFloat, _ oldEndValue: CGFloat, _ newStartValue: CGFloat, _ newEndValue: CGFloat) -> CGFloat  {
    return clamp(remap(value,oldStartValue,oldEndValue,newStartValue,newEndValue), newStartValue, newEndValue)
}

public func remapNormalizeClamp(_ value: CGFloat, _ oldStartValue: CGFloat, _ oldEndValue: CGFloat) -> CGFloat  {
    return clamp(normalize(value, oldStartValue, oldEndValue), 0, 1)
}


extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
extension Strideable where Self.Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
