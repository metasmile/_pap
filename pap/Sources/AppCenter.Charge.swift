//
// Created by BLACKGE?NE ?on 24.07.18.
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
        AppCharge(type: .welcomeFreeTrial, reward: .timeOfUses,  priceAmount: AmountObject(value:AppChargeBanker.InitialTutorialTimeOfUsesDay/AppChargeBanker.AbsTimeOfUsesDay), title:"Welcome Free Tutorial".localized, description:nil)
        , AppCharge(type: .inStoreRating, reward: .nonBlockOfUses,  priceAmount: AmountObject(value:0.0), title:"Write A Review".localized, description:nil)
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
private final class AppChargeBanker: ChargeBanker, ChargeReceiptStorable {
    fileprivate static let version:Int = 1

    private let appShortVersionDescription = Defaults.shared.shortVersionDescription
    private lazy var receiptStorage = ChargeReceiptStorage(accessor:self)

    fileprivate static let AbsTimeDayUnit:TimeInterval = 60*60*24
    fileprivate static let AbsTimeOfUsesDay:TimeInterval = 30
    fileprivate static let AbsTimeOfUsesTime:TimeInterval = AbsTimeOfUsesDay * AbsTimeOfUsesDay

    fileprivate static let InitialTutorialTimeOfUsesDay:TimeInterval = 3

    fileprivate static let AbsCountOfUsesCount = 50

    private let registeredCharges:[Charge]

    init(registeredCharges: [Charge]) {
        self.registeredCharges = registeredCharges
    }

    func willInitialize(balance: MutableAmount) -> Amount {
        return self.synchronizeBalance(balance:balance)
    }

    func didInitialize(balance: MutableAmount) {
        switch appShortVersionDescription{
            case .first:
                if let welcomeCharge = self.registeredCharges.first(where:{ charge in
                    return charge.type == .welcomeFreeTrial
                }){
                    //give tutorial balance 3 days
                    assert(balance.value==0, "User installs the app firstly but why balance is not 0?")
                    balance.add(welcomeCharge.priceAmount)
                    createReceipt(for:welcomeCharge, balance:balance)
                }

            case .reversed, .unhandled:
                balance.set(AmountObject(value: 0))
                synchronizeBalance(balance:balance)

            default:
                break
        }

        print("[i] \(String(describing: type(of: self))) Initializd. Balace: ", balance.value)
    }

    private func createReceipt(for charge: Charge, balance: MutableAmount){
        var receipt = ChargeableReceipt(chargeable: charge, bankerVersion: AppChargeBanker.version)
        receipt.dateData = Date()
        receiptStorage.addReceipt(receipt)
        synchronizeBalance(balance:balance)
        print("[i] Receipt Saved: ", receipt, receipt.uuid)
    }

    @discardableResult
    private func synchronizeBalance(balance: MutableAmount) -> Amount{
        let initialBalance = balance.value
        var removingReceipts = Set<ChargeableReceipt>()

        for (_, receipt) in receiptStorage.receipts { //TODO: improve performance - o.n -> o.1 avg.

            guard let charge = registeredCharges.first(where:{ charge in charge.isEqual(other: receipt)}) else {
                continue
            }

            switch receipt.reward{
                case .nonBlockOfUses:
                    break

                case .timeOfUsesByVersion,
                     .countOfUsesByVersion,
                     .ownedByVersion where appShortVersionDescription == .new:
                    removingReceipts.insert(receipt)

                case .timeOfUses:
                    if let date = receipt.dateData{
                        let newDate = Date()
                        let totalRewardTime = type(of: self).AbsTimeOfUsesTime * charge.priceAmount.value/type(of: balance).maxValue
                        let spentRatio = normalize(newDate.timeIntervalSince(date), 0, totalRewardTime)

                        var updatingReceipt = receipt
                        updatingReceipt.dateData = newDate
                        receiptStorage.updateReceipt(updatingReceipt)

                        print("[i] timeOfUses will subtract - balance:", balance.value)
                        balance.subtractShares(of: charge.priceAmount, ratio: spentRatio)
                        print("[i] timeOfUses did subtract - balance:", balance.value)

                        if spentRatio >= 1{
                            removingReceipts.insert(receipt)
                        }
                    }
                default:
                    assert(false, "[!] WARNING: \(receipt.reward) handling is not implemented yet.")
            }
        }

        if initialBalance > 0 && balance.value==0{
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

    func willSynchronizeBalanceValue(balance: MutableAmount) -> Amount {
        return synchronizeBalance(balance:balance)
    }

    func willSaveDeposit(forPriceAmountOf charge: Charge, balance: MutableAmount) -> Amount? {
        return charge.priceAmount
    }

    func didSaveDeposit(for charge: Charge, balance: MutableAmount) {
        createReceipt(for: charge, balance:balance)
    }
}
