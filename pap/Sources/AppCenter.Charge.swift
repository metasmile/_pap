//
// Created by BLACKGENE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit


struct AppChargeableItem: Codable, Chargeable{
    let type: ChargeType
    let reward: RewardType

    init(type:ChargeType, reward:RewardType){
        self.type = type
        self.reward = reward
    }

    private enum CodingKeys: Int, CodingKey {
        case type
        case reward

        case dateData
        case stringData
        case intData
        case doubleData
        case dataData
    }

    var dateData:Date?
    var stringData:String?
    var intData:Int?
    var doubleData:Double?
    var dataData:Data?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(reward, forKey: .reward)

        try container.encode(dateData, forKey: .dateData)
        try container.encode(stringData, forKey: .stringData)
        try container.encode(intData, forKey: .intData)
        try container.encode(doubleData, forKey: .doubleData)
        try container.encode(dataData, forKey: .dataData)
    }
}

private struct AppChargeItem: Charge {
    var type: ChargeType
    var reward: RewardType

    let priceAmount:Amount
    let title: String
    let description: String?
}


extension AppCenter{
    static let charge:ChargeManager = AppChargeManager.shared
}

private final class AppChargeManager: ChargeManager{
    fileprivate static let shared = AppChargeManager(charges:[
        AppChargeItem(type: .inStoreRating, reward: .timeOfUses,  priceAmount: MutableAmountObject(value:0.1), title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .onPromptRating, reward: .timeOfUses, priceAmount: MutableAmountObject(value:0.2), title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .socialShare, reward: .timeOfUses, priceAmount: MutableAmountObject(value:0.5), title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .feedback, reward: .timeOfUses, priceAmount: AmountObject(value:1), title:"AppStore Rating", description:nil)
        /* .... */
    ], banker: AppChargeBank.self)
}

private protocol AppChargeBankDefaults:DefaultsProperty{
    var deposited:[AppChargeableItem] {set get}
}

extension Defaults: AppChargeBankDefaults {
    var deposited:[AppChargeableItem]{
        set{ set(newValue) }
        get{ return get(or:[AppChargeableItem]()) }
    }
}

private final class AppChargeBank: ChargeBanker {
    private var defaults: AppChargeBankDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: AppChargeBank.self)+"UserDefaults") ?? UserDefaults.standard)

    private let papAbsTimeOfUsesTime:TimeInterval = 60*60*24*14 //14d
    private let papAbsTotalPerformCount = 50

    init() {}

    func willInitialize(balance: MutableAmount) -> Amount {
        //DEBUG
        defaults.deposited = [AppChargeableItem]()
        return AmountObject(value: 0)

//        return balance
    }

    func willGetBalanceValue(balance: MutableAmount) -> Amount {
        for chargeable in defaults.deposited {
            guard let charge = AppChargeManager.shared.getCharge(for: chargeable) else {
                continue
            }

            if chargeable.reward == RewardType.timeOfUses, let date = chargeable.dateData{
                if Date().timeIntervalSince(date) > papAbsTimeOfUsesTime{

                    balance.subtract(charge.priceAmount)
                }
            }

        }

        return balance
    }

    func willDeposit(priceAmountFor charge: Charge, balance: MutableAmount) -> Amount? {

        var item = AppChargeableItem(type: charge.type, reward: charge.reward)
        item.dateData = Date()

        defaults.deposited.append(item)

        return charge.priceAmount
    }

    func didDeposit(for charge: Charge, balance: MutableAmount) {
    }
}