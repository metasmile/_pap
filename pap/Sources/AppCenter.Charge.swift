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

    init(type:ChargeType, reward:RewardType, data:Codable){
        self.init(type: type, reward: reward)
        self.data = data
    }

    var data:Codable?

    private enum CodingKeys: Int, CodingKey {
        case type
        case reward
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(reward, forKey: .reward)
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
    static let charge:ChargeManager = papChargeManager(charges:[
        AppChargeItem(type: .inStoreRating, reward: .timeOfUses,  priceAmount: MutableAmountObject(value:0.1), title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .onPromptRating, reward: .timeOfUses, priceAmount: MutableAmountObject(value:0.2), title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .socialShare, reward: .timeOfUses, priceAmount: MutableAmountObject(value:0.5), title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .feedback, reward: .timeOfUses, priceAmount: AmountObject(value:1), title:"AppStore Rating", description:nil)
        /* .... */
    ], banker: AppChargeBank.self)
}

private final class papChargeManager: ChargeManager{

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

    func willGetBalanceValue(balance: MutableAmount) -> Amount {
        for chargeable in defaults.deposited {

            if chargeable.reward == RewardType.timeOfUses, let date = chargeable.data as? Date{
                if Date().timeIntervalSince(date) > papAbsTimeOfUsesTime{

                }
            }

        }

        return balance
    }

    func willInitialize(balance: MutableAmount) -> Amount {
        return balance
    }

    func willDeposit(priceAmountFor charge: Charge, balance: MutableAmount) -> Amount? {

        defaults.deposited.append(AppChargeableItem(type: charge.type, reward: charge.reward, data:Date()))

        return charge.priceAmount
    }

    func didDeposit(for charge: Charge, balance: MutableAmount) {
    }
}