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

private final class AppChargeBanker: ChargeBanker, ChargeReceiptStorageAccessor {
    fileprivate static let version:Int = 1

    private lazy var receiptStorage = ChargeReceiptStorage(accessor:self)

    private let papAbsTimeOfUsesTime:TimeInterval = 30//60*60*24*14 //14d
    private let papAbsTotalPerformCount = 50

    init() {}

    private func synchronizeBalance(balance: MutableAmount) -> Amount{
        var removingReceipts = Set<ChargeableReceipt>()

        for (_, receipt) in receiptStorage.receipts {

            guard let charge = AppChargeManager.shared.getCharge(for: receipt) else {
                continue
            }

            if receipt.reward == RewardType.timeOfUses, let date = receipt.dateData{
                let newDate = Date()
                let spentRatio = normalize(newDate.timeIntervalSince(date),0,papAbsTimeOfUsesTime)

                var updatingReceipt = receipt
                updatingReceipt.dateData = newDate
                receiptStorage.updateReceipt(updatingReceipt)

                balance.subtractShares(of: charge.priceAmount, ratio: spentRatio)
                
                if spentRatio >= 1{
                    removingReceipts.insert(receipt)
                }
            }
        }

        if balance.value==0{
            removingReceipts = Set(receiptStorage.receipts.values)
        }

        for r in removingReceipts {
            receiptStorage.removeReceipt(r.uuid)
            print("[i] INFO: Removed Receipts: ", r.uuid)
        }
        
        receiptStorage.commit()
        
        return balance
    }

    func willInitialize(balance: MutableAmount) -> Amount {
        //DEBUG
        receiptStorage.disposeAll()
        return AmountObject(value: 0)
//        return self.synchronizeBalance(balance:balance)
    }

    func willSynchronizeBalanceValue(balance: MutableAmount) -> Amount {
        return self.synchronizeBalance(balance:balance)
    }

    func willSaveDeposit(forPriceAmountOf charge: Charge, balance: MutableAmount) -> Amount? {
        var receipt = ChargeableReceipt(chargeable: charge, bankerVersion: AppChargeBanker.version)
        receipt.dateData = Date()

        receiptStorage.addReceipt(receipt)
        receiptStorage.commit()

        print("[i] Deposited: ", receipt, receipt.uuid)

        return charge.priceAmount
    }

    func didSaveDeposit(for charge: Charge, balance: MutableAmount) {

    }
}
