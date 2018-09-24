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

    static var min:Period{
        return Period(numberOfUnits: 0, unit: .second)
    }

    func asString(roundTo places:Int, trimTrailingZeros:Bool=true) -> String{
        return numberOfUnits.roundedString(toPlaces: places, trimTrailingZeros: trimTrailingZeros)
    }

    static func ==(lhs: Period, rhs: Period) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var hashValue: Int {
        return (String(describing: numberOfUnits)+String(describing: unit)).hashValue
    }

    func within(since date:Date) -> Bool {
        return within(dueDate: Date(), since: date)
    }

    func within(dueDate:Date, since date:Date) -> Bool {
        guard dueDate != date else{
            return false
        }

        let interval = dueDate.timeIntervalSince(date)
        guard interval > 0 else {
            return false
        }

        switch(self.unit) {
            case .second:
                return interval < numberOfUnits
            case .minute:
                return interval < numberOfUnits * 60*60
            case .hour:
                return interval < numberOfUnits * 60*60
            case .day:
                return interval < numberOfUnits * 60*60 * 24
            case .week:
                return interval < numberOfUnits * 60*60 * 24 * 7
            case .month:
                return interval < numberOfUnits * 60*60 * 24 * 30.436875
            case .year:
                return interval < numberOfUnits * 60*60 * 24 * 30.436875 * 12
        }
    }
}
