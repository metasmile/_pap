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
        AppCharge(type: .inStoreRating, reward: .nonBlockOfUses,  priceAmount: AmountObject(value:0.0), title:"Write A Review".localized, description:nil)
        , AppCharge(type: .onPromptRating, reward: .nonBlockOfUses, priceAmount: AmountObject(value:0.0), title:"Give A Rating".localized, description:nil)
        , AppCharge(type: .socialShare, reward: .timeOfUses, priceAmount: AmountObject(value:0.5), title:"Share This App".localized, description:nil)
        , AppCharge(type: .feedback, reward: .timeOfUses, priceAmount: AmountObject(value:0.5), title:"Send Us Feedback".localized, description:nil)
        /* .... */
    ], banker: AppChargeBanker.self)
}

extension Charge{
    private var daysFormattedStringWithPriceAmount:String?{
        return (self.priceAmount.value * AppChargeBanker.AbsTimeOfUsesDay).roundedString(toPlaces: 1, trimTrailingZeros: true)
    }

    var titleWithReward:String {
        guard let daysString = daysFormattedStringWithPriceAmount else{
            return self.title
        }

        switch (self.reward) {
            case .timeOfUses:
                return "\(self.title) (\("%@ Day License".localizedFormatted(daysString)))"
            default:
                return self.title
        }
    }
    
    var shortTitleWithReward:String? {
        guard let daysString = daysFormattedStringWithPriceAmount else{
            return nil
        }

        switch (self.reward) {
            case .timeOfUses:
                return "%@ Day".localizedFormatted(daysString)
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

/*
POLICY

1.0
First Installed User: Non consumption all



*/

private final class AppChargeBanker: ChargeBanker, ChargeReceiptStorable {
    fileprivate static let version:Int = 1

    private let shortVersionDescription = Defaults.shared.shortVersionDescription
    private lazy var receiptStorage = ChargeReceiptStorage(accessor:self)

    fileprivate static let AbsTimeDayTime:TimeInterval = 60*60*24
    fileprivate static let AbsTimeOfUsesDay:TimeInterval = 7
    fileprivate static let AbsTimeOfUsesTime:TimeInterval = AbsTimeOfUsesDay * AbsTimeOfUsesDay

    fileprivate static let AbsCountOfUsesCount = 50

    init() {}

    private func synchronizeBalance(balance: MutableAmount) -> Amount{
        let wasZeroBalance = balance.value==0
        var removingReceipts = Set<ChargeableReceipt>()

        for (_, receipt) in receiptStorage.receipts { //TODO: improve performance - o.n -> o.1 avg.

            guard let charge = AppChargeManager.shared.getCharge(for: receipt) else {
                continue
            }

            if receipt.reward == RewardType.timeOfUses, let date = receipt.dateData{
                let newDate = Date()
                let totalRewardTime = type(of: self).AbsTimeOfUsesTime * charge.priceAmount.value/type(of: balance).maxValue
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
