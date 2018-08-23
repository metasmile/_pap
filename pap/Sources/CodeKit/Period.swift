//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

struct Period:Equatable, Hashable, Codable {
    enum Unit : UInt, Codable {
        case second
        case minute
        case hour
        case day
        case week
        case month
        case year
    }
    var numberOfUnits: Double
    var unit: Unit

    func asString(roundTo places:Int, trimTrailingZeros:Bool=true) -> String{
        return numberOfUnits.roundedString(toPlaces: places, trimTrailingZeros: trimTrailingZeros)
    }

    static func ==(lhs: Period, rhs: Period) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var hashValue: Int {
        return (String(describing: numberOfUnits)+String(describing: unit)).hashValue
    }
}
