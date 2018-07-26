//
// Created by BLACKGE?NE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit


extension AppCenter{
    static let charge:ChargeManager = AppChargeManager.shared
}

private final class AppChargeManager: ChargeManager{
    fileprivate static let shared = AppChargeManager(charges:[
        AppCharge(type: .inStoreRating, reward: .timeOfUses,  priceAmount: MutableAmountObject(value:0.1), title:"AppStore Rating", description:nil)
        , AppCharge(type: .onPromptRating, reward: .timeOfUses, priceAmount: MutableAmountObject(value:0.2), title:"AppStore Rating", description:nil)
        , AppCharge(type: .socialShare, reward: .timeOfUses, priceAmount: MutableAmountObject(value:0.5), title:"AppStore Rating", description:nil)
        , AppCharge(type: .feedback, reward: .timeOfUses, priceAmount: AmountObject(value:1), title:"AppStore Rating", description:nil)
        /* .... */
    ], banker: AppChargeBank.self)
}

private struct AppCharge: Charge {
    var type: ChargeType
    var reward: RewardType

    let priceAmount:Amount
    let title: String
    let description: String?
}

struct AppChargeable: Chargeable{
    let type: ChargeType
    let reward: RewardType

    init(type:ChargeType, reward:RewardType){
        self.type = type
        self.reward = reward
    }
}

struct AppChargeableReceipt: Codable, Chargeable{

    init(chargeable:Chargeable){
        self.type = chargeable.type
        self.reward = chargeable.reward
    }

    let uuid:String = UUID().uuidString
    let createdDate:Date = Date()
    let bankVersion:Int = AppChargeBank.version

    let type: ChargeType
    let reward: RewardType

    var dateData:Date?
    var stringData:String?
    var intData:Int?
    var doubleData:Double?
    var dataData:Data?

    private enum CodingKeys: Int, CodingKey {
        case uuid
        case createdDate
        case bankVersion

        case type
        case reward

        case dateData
        case stringData
        case intData
        case doubleData
        case dataData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(bankVersion, forKey: .bankVersion)

        try container.encode(type, forKey: .type)
        try container.encode(reward, forKey: .reward)

        try container.encode(dateData, forKey: .dateData)
        try container.encode(stringData, forKey: .stringData)
        try container.encode(intData, forKey: .intData)
        try container.encode(doubleData, forKey: .doubleData)
        try container.encode(dataData, forKey: .dataData)
    }
}

private protocol AppChargeBankDefaults:DefaultsProperty{
    var receipts:[String: AppChargeableReceipt] {set get} // receipt ID : object
}

extension Defaults: AppChargeBankDefaults {
    var receipts:[String: AppChargeableReceipt]{
        set{ set(newValue) }
        get{ return get(or:[String: AppChargeableReceipt]()) }
    }
}

private final class AppChargeBank: ChargeBanker {
    fileprivate static let version:Int = 1

    private var defaults: AppChargeBankDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: AppChargeBank.self)+"UserDefaults") ?? UserDefaults.standard)

    private let papAbsTimeOfUsesTime:TimeInterval = 30//60*60*24*14 //14d
    private let papAbsTotalPerformCount = 50

    init() {}

    func willInitialize(balance: MutableAmount) -> Amount {
        //DEBUG
        defaults.receipts = [String: AppChargeableReceipt]()
        return AmountObject(value: 0)

//        return balance
    }

    //TODO: performance care
    func willGetBalanceValue(balance: MutableAmount) -> Amount {
        var subtractedReceiptIds = [String]()

        for (uuid, receipt) in defaults.receipts {

            guard let charge = AppChargeManager.shared.getCharge(for: receipt) else {
                continue
            }

            if receipt.reward == RewardType.timeOfUses, let date = receipt.dateData{
                if Date().timeIntervalSince(date) > papAbsTimeOfUsesTime{
                    subtractedReceiptIds.append(uuid)

                    print("before", balance.value)
                    balance.subtract(charge.priceAmount)
                    print("after subtract", balance.value)
                }
            }
        }

        var receipts = defaults.receipts
        for id in subtractedReceiptIds {
            print("[i] INFO: Removed Receipt: ", receipts[id] ?? "", id)
            receipts.removeValue(forKey: id)
        }
        defaults.receipts = receipts
        
        return balance
    }

    func willSaveDeposit(priceAmountFor charge: Charge, balance: MutableAmount) -> Amount? {

        var receipt = AppChargeableReceipt(chargeable: charge)
        receipt.dateData = Date()

        defaults.receipts[receipt.uuid] = receipt

        print("[i] Deposited: ", receipt, receipt.uuid)

        return charge.priceAmount
    }

    func willSaveDeposit(for charge: Charge, balance: MutableAmount) {
    }
}
