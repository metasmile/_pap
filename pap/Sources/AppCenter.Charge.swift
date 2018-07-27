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
        AppCharge(type: .inStoreRating, reward: .nonBlockOfUses,  priceAmount: AmountObject(value:0.0), title:"Review In App Store", description:nil)
        , AppCharge(type: .onPromptRating, reward: .nonBlockOfUses, priceAmount: AmountObject(value:0.0), title:"Rate", description:nil)
        , AppCharge(type: .socialShare, reward: .timeOfUses, priceAmount: AmountObject(value:0.5), title:"Share This App", description:nil)
        , AppCharge(type: .feedback, reward: .timeOfUses, priceAmount: AmountObject(value:1), title:"Send Us Feedback", description:nil)
        /* .... */
    ], banker: AppChargeBanker.self)


}

extension Charge{
    var titleApplyingReward:String {
        switch (self.reward) {

        case .timeOfUses where self.priceAmount.value>0:
            let days = (self.priceAmount.value * AppChargeBanker.papAbsTimeOfUsesDay).roundedString(toPlaces: 1, trimTrailingZeros: true)
            let license = "%@ Day License".localizedFormatted(days)
            return "\(self.title) (\(license))"
        default:
            return self.title
        }
    }
    
    var rewardDescription:String? {
        switch (self.reward) {
            
        case .timeOfUses where self.priceAmount.value>0:
            let days = (self.priceAmount.value * AppChargeBanker.papAbsTimeOfUsesDay).roundedString(toPlaces: 1, trimTrailingZeros: true)
            return "%@ Day".localizedFormatted(days)
        default:
            return nil
        }
    }
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

private final class AppChargeBanker: ChargeBanker, ChargeReceiptStorable {
    fileprivate static let version:Int = 1

    private lazy var receiptStorage = ChargeReceiptStorage(accessor:self)

    fileprivate static let papAbsTimeDayUnit:TimeInterval = 60*60*24
    fileprivate static let papAbsTimeOfUsesDay:TimeInterval = 7
    fileprivate static let papAbsTimeOfUsesTime:TimeInterval = papAbsTimeOfUsesDay*papAbsTimeDayUnit

    fileprivate static let papAbsTotalPerformCount = 50

    init() {}

    private func synchronizeBalance(balance: MutableAmount) -> Amount{
        let wasZeroBalance = balance.value==0
        var removingReceipts = Set<ChargeableReceipt>()

        for (_, receipt) in receiptStorage.receipts {

            guard let charge = AppChargeManager.shared.getCharge(for: receipt) else {
                continue
            }

            if receipt.reward == RewardType.timeOfUses, let date = receipt.dateData{
                let newDate = Date()
                let totalRewardTime = type(of: self).papAbsTimeOfUsesTime * charge.priceAmount.value/type(of: balance).maxValue
                let spentRatio = normalize(newDate.timeIntervalSince(date), 0, totalRewardTime)

                var updatingReceipt = receipt
                updatingReceipt.dateData = newDate
                receiptStorage.updateReceipt(updatingReceipt)

                balance.subtractShares(of: charge.priceAmount, ratio: spentRatio)
                
                if spentRatio >= 1{
                    removingReceipts.insert(receipt)
                }
            }
        }

        if wasZeroBalance == false && balance.value==0{
            removingReceipts = Set(receiptStorage.receipts.values)
        }

        for r in removingReceipts {
            receiptStorage.removeReceipt(r.uuid)
            print("[i] INFO: Removed Receipts: ", r.uuid)
        }

        DispatchQueue.global().async{
            self.receiptStorage.commit()
        }
        return balance
    }

    func getReceipt(for chargeable: Chargeable) -> ChargeableReceipt? {
        return receiptStorage.getReceipt(for: chargeable)
    }

    func willInitialize(balance: MutableAmount) -> Amount {
        //DEBUG
        for r in receiptStorage.receipts.keys{
            receiptStorage.removeReceipt(r)
        }
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
