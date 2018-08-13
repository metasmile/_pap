//
// Crea??ted by BLACKGENE on 25.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//INFO: WARNING: rawValue is ID so they must be unique value forever. do not use same again.
enum ChargeType:Int {
    case deprecated = -1

    //promotional
    case welcomeFreeTrial = 100
    case inStoreRating = 101
    case onPromptRating = 102
    case socialShare = 103
    case feedback = 104
    case ads = 105

    //very special promotional
    case vipCode = 200 //it will match with new hash value for each new version

    //paid
    case nonConsumablePurchase = 300
    case consumablePurchase = 301
    case nonRenewingMonthlySubscription = 302
    case nonRenewingYearlySubscription = 303
    case renewableMonthlySubscription = 304
    case renewableYearlySubscription = 305
}

enum RewardType:Int {
    case deprecated = -1

    //will be engaged only nonSelected
    case nonBlockOfUses = 100

    //e.g. promotional
    case timeOfUses = 200
    case countOfUses = 201

    //e.g. paid or VIP code
    case owned = 300
    case rented = 301

    var isNonConsumable:Bool{
        switch self{
            case .owned, .rented, .nonBlockOfUses:
                 return true
            default:
                break
        }
        return false
    }
}

protocol ChargeDescribable{
    var title:String {get}
    var description:String? {get}
    var iconImage:ImageSourceable? {get}
}

protocol RewardDescribable{
    var title:String? {get}
    var shortTitle:String? {get}
    var description:String? {get}
    var unit:String? {get}
    var iconImage:ImageSourceable? {get}
}

protocol Payable {
    static var label:String {get}

    func pay(_ asyncSignal:AsyncWaitSignalable) -> Bool

    init()
}

protocol VerifiablePayable: Payable {
    //INFO:
    // nil: error or it can not handle currently. usually should handle later.
    // true: purchase
    // false: clearly not purchased/expired
    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool?
}

protocol StorePayable: VerifiablePayable {
    static var product: StorePayableProduct {get}
}

protocol StorePayableProduct {
    var identifier:String {get}
}

struct StoreProduct:StorePayableProduct {
    let identifier:String
}

protocol Chargeable {
    var type: ChargeType {get}
    var reward: RewardType {get}
    var payment:Payable.Type {get} //INFO: Chargeable : Payment = 1 : 1 currently.
    var identifier:String {get}
}

extension Chargeable{
    func isEqualTo(other:Chargeable) -> Bool{
        return other.identifier == identifier
    }
    var identifier:String{
        return String(describing: Chargeable.self) +
                "-type_\(type)" +
                "-reward_\(reward)" +
                "-payment_\(String(describing: self.payment))"
    }
}

extension Equatable where Self:Chargeable{
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.isEqualTo(other:rhs)
    }
}

//INFO: It is not recommended what use a type Charge directly outside of Bank.
// Use "AppCenter.charge.getCharge(for: chargeable)"
protocol Charge: Chargeable {
    var priceAmount: Amount {get}
    var describable:ChargeDescribable {get}
    var rewardDescribable:RewardDescribable? {get}
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
