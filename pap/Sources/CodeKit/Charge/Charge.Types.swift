//
// Created by BLACKGENE on 25.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

enum ChargeType:Int, Codable {
    //promotional
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
    //e.g. promotional
    case timeOfUsesByVersion // while uses on single version
    case timeOfUses
    case countOfUsesByVersion
    case countOfUses
    case ownedByVersion

    //e.g. paid or VIP code
    case owned
}

protocol Payable {
    static var charge: Chargeable {get}

    func pay(_ asyncSignal:AsyncWaitSignalable) -> Bool

    init()
}

protocol Chargeable {
    var type: ChargeType {set get}
    var reward:RewardType {set get}
}

extension Chargeable{
    func isEqual(other:Chargeable) -> Bool{
        return reward==other.reward && type==other.type
    }
}

protocol Charge: Chargeable {
    var priceAmount: Amount {get}

    var title:String {get}
    var description:String? {get}
}

protocol Amount{
    var value:Double{get}

    init(value:Double)
}

protocol MutableAmount: Amount{
    func add(_ amount:Amount) -> Amount
    func subtract(_ amount:Amount) -> Amount
}