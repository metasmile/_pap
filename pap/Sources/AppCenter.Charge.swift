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
    ], banker: AppChargeBanker.self)
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

private protocol AppChargeBankDefaults:DefaultsProperty{
    var receipts:[String: ChargeableReceipt] {set get} // receipt ID : object
}

extension Defaults: AppChargeBankDefaults {
    var receipts:[String: ChargeableReceipt]{
        set{ set(newValue) }
        get{ return get(or:[String: ChargeableReceipt]()) }
    }
}

private struct AppReceiptAccessor { //struct means final.
    private var receiptsStorage: AppChargeBankDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: AppReceiptAccessor.self)+"Storage") ?? UserDefaults.standard)

    private(set) var receipts:[String: ChargeableReceipt]

    init(){
        receipts = receiptsStorage.receipts
    }

    mutating func addReceipt(_ receipt: ChargeableReceipt){
        receiptsStorage.receipts[receipt.uuid] = receipt
        receipts = receiptsStorage.receipts
    }

    mutating func removeReceipt(_ receiptId:String){
        receiptsStorage.receipts[receiptId] = nil
        receipts = receiptsStorage.receipts
    }

    mutating fileprivate func disposeAll(){
        receiptsStorage.receipts.removeAll()
        receipts.removeAll()
    }
}

private final class AppChargeBanker: ChargeBanker {
    fileprivate static let version:Int = 1

    private lazy var receiptAccessor = AppReceiptAccessor()

    private let papAbsTimeOfUsesTime:TimeInterval = 30//60*60*24*14 //14d
    private let papAbsTotalPerformCount = 50

    init() {}

    private func synchronizeBalance(balance: MutableAmount) -> Amount{
        var subtractedReceiptIds = [String]()

        for (uuid, receipt) in receiptAccessor.receipts {

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

        for id in subtractedReceiptIds {
            receiptAccessor.removeReceipt(id)
            print("[i] INFO: Removed Receipt: ", id)
        }
        return balance
    }

    func willInitialize(balance: MutableAmount) -> Amount {
        //DEBUG
        receiptAccessor.disposeAll()
        return AmountObject(value: 0)
//        return self.synchronizeBalance(balance:balance)
    }

    func willSynchronizeBalanceValue(balance: MutableAmount) -> Amount {
        return self.synchronizeBalance(balance:balance)
    }

    func willSaveDeposit(forPriceAmountOf charge: Charge, balance: MutableAmount) -> Amount? {
        var receipt = ChargeableReceipt(chargeable: charge, bankerVersion: AppChargeBanker.version)
        receipt.dateData = Date()

        receiptAccessor.addReceipt(receipt)

        print("[i] Deposited: ", receipt, receipt.uuid)

        return charge.priceAmount
    }

    func didSaveDeposit(for charge: Charge, balance: MutableAmount) {

    }
}
