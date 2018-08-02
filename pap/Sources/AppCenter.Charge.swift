//
// Created by BLACKGE?NE ??on 24.07.18.
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
        AppCharge(type: .welcomeFreeTrial, reward: .timeOfUses,  priceAmount: AmountObject(value:AppChargeBanker.InitialTutorial_TimeOfUses_Day/AppChargeBanker.Abs_TimeOfUses_Day), title:"Welcome Free Trial Pack".localized, description:nil)

        , AppCharge(type: .onPromptRating, reward: .nonBlockOfUses, priceAmount: AmountObject(value:0.0), title:"Give A Rating".localized, description:nil)
        , AppCharge(type: .inStoreRating, reward: .nonBlockOfUses,  priceAmount: AmountObject(value:0.0), title:"Write A Review".localized, description:nil)
        , AppCharge(type: .socialShare, reward: .timeOfUses, priceAmount: AmountObject(value:0.5), title:"Share This App".localized, description:nil)
        , AppCharge(type: .feedback, reward: .timeOfUses, priceAmount: AmountObject(value:0.5), title:"Send Us Feedback".localized, description:nil)
        /* .... */
    ], banker: AppChargeBanker.self)
}

extension Charge{
    private var daysFormattedStringWithPriceAmount:String?{
        return (self.priceAmount.value * AppChargeBanker.Abs_TimeOfUses_Day).roundedString(toPlaces: 1, trimTrailingZeros: true)
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

Tn : T3 : Tutorial 3 Day
Bn : B1.0 : Balance Full

ChargeableApp.charge? -> Purchase App -> Pricing VC/Alert

| Version                 | Policy
-------------------------------------------------------
| First ... Normal T3              | Rating? + Balance?
| First -> Normal -> B(n(>0)...x)  | Rating? + Balance!
| Normal -> New   -> B(n(>0)...x)  | Rating! + Balance!


ChargeableApp.charge! -> Pricing VC/Alert

*/
private final class AppChargeBanker: ChargeBanker {
    fileprivate static let version:Int = 1

    private(set) var receiptStorageIdentifier: String = "com.stells.AppChargeBanker.receiptStorage"

    private let appShortVersionDescription = Defaults.shared.shortVersionDescription
    private lazy var receiptStorage = ChargeReceiptStorage(banker:self)

    fileprivate static let Abs_TimeOfUses_DayTimeUnit:TimeInterval = 8//60*60*24
    fileprivate static let InitialTutorial_TimeOfUses_Day:TimeInterval = 3
    fileprivate static let Abs_TimeOfUses_Day:TimeInterval = 30
    fileprivate static let Abs_TimeOfUses_Time:TimeInterval = Abs_TimeOfUses_Day * Abs_TimeOfUses_DayTimeUnit

    private static let ChargeTypesAvailableOnlyCurrentVersion = Set([
        ChargeType.inStoreRating
        , ChargeType.onPromptRating
    ])

    fileprivate static let Abs_CountOfUses_Count = 50

    private let registeredCharges:[Charge]

    init(registeredCharges: [Charge]) {
        self.registeredCharges = registeredCharges
    }

    func initializeBank() -> Amount {

        let initialBalance = AmountObject(value: clamp(receiptStorage.balanceAmountValue, AmountObject.minValue, AmountObject.maxValue))

        switch appShortVersionDescription{
            case .first:
                if let welcomeCharge = self.registeredCharges.first(where:{ charge in
                    return charge.type == .welcomeFreeTrial
                }){
                    //give tutorial balance 3 days
                    assert(initialBalance.value == 0, "User installs the app firstly but why balance is not 0?")
                    createOrReplaceReceipt(for:welcomeCharge)
                }

            case .reversed, .unhandled:
                assert(false, "Wrong version direction. Install new one.")
                for r in receiptStorage.receipts{
                    receiptStorage.removeReceipt(r.key)
                }

            default:
                break
        }

        print("[i] \(String(describing: type(of: self))) Initializd. Balance: ", initialBalance.value)

        return self.synchronizeBalance(balance:initialBalance)
    }

    func didInitializeBank(balance: Amount) {

    }

    private func createOrReplaceReceipt(for charge: Charge){
        var receipt = ChargeableReceipt(charge: charge, bankerVersion: AppChargeBanker.version)
        receipt.dateData = Date()

        if let existedReceiptItem = receiptStorage.receipts.first(where:{ key, value in
            value.isEqualTo(other: charge)
        }){
            receiptStorage.removeReceipt(existedReceiptItem.value.uuid)
            receiptStorage.addReceipt(receipt)

        }else{
            receiptStorage.addReceipt(receipt)
        }

        print("[i] Receipt Saved: ", receipt, receipt.uuid)
    }

    @discardableResult
    private func synchronizeBalance(balance: Amount) -> Amount{
        var removingReceipts = Set<ChargeableReceipt>()
        let syncDate = Date()

        for (_, receipt) in receiptStorage.receipts { //TODO: improve performance - o.n -> o.1 avg.

            guard let charge = registeredCharges.first(where:{ charge in charge.isEqualTo(other: receipt)}) else {
                continue
            }

            // expired on new version
            if appShortVersionDescription == .new && type(of: self).ChargeTypesAvailableOnlyCurrentVersion.contains(receipt.type){
                removingReceipts.insert(receipt)
                continue
            }

            //deprecated
            if receipt.type == .deprecated || receipt.reward == .deprecated{
                removingReceipts.insert(receipt)
                continue
            }

            switch receipt.reward{
                case .nonBlockOfUses:
                    break

                case .timeOfUses:
                    if let date = receipt.dateData{
                        let totalOffset = type(of: self).Abs_TimeOfUses_Time * charge.priceAmount.value
                        let offset = syncDate.timeIntervalSince(date)
                        let amountValueOffsetRatio = offset/totalOffset

                        let newAmountValue = receipt.amountValue - (charge.priceAmount.value * amountValueOffsetRatio)
                        if newAmountValue > 0{
                            var updatingReceipt = receipt
                            updatingReceipt.amountValue = newAmountValue
                            updatingReceipt.dateData = syncDate
                            receiptStorage.updateReceipt(updatingReceipt)

                            print("[i] Updated Receipt: \ntype: \(receipt.type), \nreward: \(receipt.reward), \ncreated: \(receipt.createdDate)")
                            print("[i] Balance:", balance.value)
                        }else{
                            removingReceipts.insert(receipt)
                        }
                    }
                default:
                    assert(false, "[!] WARNING: \(receipt.reward) handling is not implemented yet.")
            }
        }

        for r in removingReceipts {
            receiptStorage.removeReceipt(r.uuid)
            print("[i] INFO: Removed Receipts: ", r, r.uuid)
        }

        self.receiptStorage.commit()

        return AmountObject(value:receiptStorage.balanceAmountValue)
    }

    func getReceipt(for chargeable: Chargeable) -> ChargeableReceipt? {
        return receiptStorage.getReceipt(for: chargeable)
    }

    func synchronizeBalanceValue(balance: Amount) -> Amount {
        return synchronizeBalance(balance:balance)
    }

    func willSaveDeposit(forPriceAmountOf charge: Charge, balance: Amount) -> Amount? {
        createOrReplaceReceipt(for: charge)
        synchronizeBalance(balance:balance)

        return charge.priceAmount
    }

    func didSaveDeposit(for charge: Charge, balance: Amount) {

    }
}
