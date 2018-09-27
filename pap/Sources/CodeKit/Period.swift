//
// Created by BLACKGENE on 8/21/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//INFO: Human-readable type of TimeInterval

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

    var localizedUnitString:String{
        switch (unit){
            case .second:
                return "second".localized
            case .minute:
                return "minute".localized
            case .hour:
                return "hour".localized
            case .day:
                return "day".localized
            case .week:
                return "week".localized
            case .month:
                return "month".localized
            case .year:
                return "year".localized
        }
    }

    func numberOfUnitString(roundTo places:Int, trimTrailingZeros:Bool=true) -> String{
        return numberOfUnits.roundedString(toPlaces: places, trimTrailingZeros: trimTrailingZeros)
    }

    static func ==(lhs: Period, rhs: Period) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var hashValue: Int {
        return (String(describing: numberOfUnits)+String(describing: unit)).hashValue
    }

    var timeInterval:TimeInterval{
        switch(unit) {
            case .second:
                return numberOfUnits
            case .minute:
                return numberOfUnits * 60
            case .hour:
                return numberOfUnits * 60*60
            case .day:
                return numberOfUnits * 60*60 * 24
            case .week:
                return numberOfUnits * 60*60 * 24 * 7
            case .month:
                return numberOfUnits * 60*60 * 24 * 30.436875
            case .year:
                return numberOfUnits * 60*60 * 24 * 30.436875 * 12
        }
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

        return interval < timeInterval
    }
}
