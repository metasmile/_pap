//
// Crea??ted by BLACKGENE on 25.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

enum ChargeType:Int, Codable {
    //promotional
    case welcomeFreeTrial
    case inStoreRating
    case onPromptRating
    case socialShare
    case feedback
    case ads

    //very special promotional
    case vipCode //it will match with new hash value for each new version

    //paid
    case nonConsumablePurchase
    case consumablePurchase
    case nonRenewingMonthlySubscription
    case nonRenewingYearlySubscription
    case renewableMonthlySubscription
    case renewableYearlySubscription
}

enum RewardType:Int, Codable {
    //will be engaged only nonSelected
    case nonBlockOfUses

    //e.g. promotional
    case timeOfUses
    case countOfUses

    //e.g. paid or VIP code
    case owned
}

protocol Payable {
    static var charge: Chargeable {get}

    func pay(_ asyncSignal:AsyncWaitSignalable) -> Bool

    init()
}

protocol Chargeable {
    var type: ChargeType {get}
    var reward: RewardType {get}
}

extension Chargeable{
    func isEqual(other:Chargeable) -> Bool{
        return reward==other.reward && type==other.type
    }
}

extension Equatable where Self:Chargeable{
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.isEqual(other:rhs)
    }
}

protocol Charge: Chargeable {
    var priceAmount: Amount {get}

    var title:String {get}
    var description:String? {get}
}

protocol Amount: Codable{
    static var minValue:Double{get}
    static var maxValue:Double{get}
    static var invalidatedValue:Double{get}

    var value:Double{get}

    init(value:Double)

    static func validate(value:Double) -> Double
}

//Default Amount
extension Amount{
    static var minValue: Double {
        return 0
    }
    static var maxValue: Double {
        return 1
    }
    static var invalidatedValue: Double {
        return Double.nan
    }

    func getValueOfShares(inContainer amount:Amount) -> Double{
        return value/type(of: amount).maxValue
    }

    static func validate(value:Double) -> Double {
        let validated = value >= minValue && value <= maxValue
        assert(validated,"The value of amount is in validate. \(value). Valid range of value is [\(minValue)...\(maxValue)]")
        return validated ? value : invalidatedValue
    }
}

protocol MutableAmount: Amount{
    @discardableResult
    func add(_ amount:Amount) -> Amount

    @discardableResult
    func subtract(_ amount:Amount) -> Amount

    @discardableResult
    func set(_ amount:Amount) -> Amount
}

extension MutableAmount{
    private func createSharesAmount(of amount:Amount, ratio:Double) -> Amount{
        return AmountObject(value: amount.getValueOfShares(inContainer: self) * ratio)
    }
    
    @discardableResult
    func addShares(of amount:Amount, ratio:Double) -> Amount{
        return self.add(createSharesAmount(of:amount, ratio:ratio))
    }

    @discardableResult
    func subtractShares(of amount:Amount, ratio:Double) -> Amount{
        return self.subtract(createSharesAmount(of:amount, ratio:ratio))
    }

    @discardableResult
    func setShares(forContained amount:Amount, ratio:Double) -> Amount{
        return self.set(createSharesAmount(of:amount, ratio:ratio))
    }
}
