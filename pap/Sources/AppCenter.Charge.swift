//
// Created by BLACKGE?NE ??on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit


extension AppCenter{
    static var charge:ChargeManager{
        return AppChargeManager.shared
    }
}

private final class AppChargeManager: ChargeManager{
    fileprivate static let shared = AppChargeManager(charges:[
        // Initial
        AppCharge(type: .welcomeFreeTrial
                , reward: .timeOfUses
                , payment:PayOfInitialTutorial.self
                , priceAmount: AmountObject(value:AppChargeBanker.InitialTutorial_TimeOfUses_Day/AppChargeBanker.Abs_TimeOfUses_Day)
                , title:"Welcome Free Trial Pack".localized
        )

        // Engagement
        , AppCharge(type: .onPromptRating
                , reward: .nonBlockOfUses
                , payment:PayOnPromptRating.self
                , priceAmount: AmountObject(value:0.0)
                , title:"Give A Rating".localized
        )

        , AppCharge(type: .inStoreRating
                , reward: .nonBlockOfUses
                ,  payment:PayInAppStoreRating.self
                , priceAmount: AmountObject(value:0.0)
                , title:"Write A Review".localized
        )

        , AppCharge(type: .socialShare
                , reward: .timeOfUses
                , payment:PayOnSocialShare.self
                , priceAmount: AmountObject(value:0.5)
                , title:"Share This App".localized
        )

        , AppCharge(type: .feedback
                , reward: .timeOfUses
                , payment:PayOnFeedback.self
                , priceAmount: AmountObject(value:0.5)
                , title:"Send Us Feedback".localized
        )

        // Store Purchase
        , AppCharge(type: .nonConsumablePurchase
                , reward: .owned, payment:PayForAllTimeAllApps.self
                , priceAmount: AmountObject.max
                , title:"Purchase All At Once".localized
                , rewardDescribable:AppRewardDescription(rewardTitle: "Permanent Use of Apps Including All New", rewardShortTitle: "Permanent Apps License", rewardDescription: nil, rewardUnit: nil)
        )

        , AppCharge(type: .consumablePurchase
                , reward: .owned
                , payment:PayForAllTimeOneApp.self
                , priceAmount: AmountObject.max
                , title:"Purchase A Single App".localized
                , rewardDescribable:AppRewardDescription(rewardTitle: "Permanent Use of This Including All Updates", rewardShortTitle: "Permanent Single App License", rewardDescription: nil, rewardUnit: nil)
        )

        , AppCharge(type: .renewableMonthlySubscription
                , reward: .rented, payment:PayForMonthlyAllApps.self
                , priceAmount: AmountObject.max
                , title:"Monthly Pass".localized
                , rewardDescribable:AppRewardDescription(rewardTitle: "Constant Use of Apps Including All New", rewardShortTitle: "Yearly Apps License", rewardDescription: nil, rewardUnit: nil)
        )
        , AppCharge(type: .renewableYearlySubscription
                , reward: .rented
                , payment:PayForYearlyAllApps.self
                , priceAmount: AmountObject.max
                , title:"Annual Pass".localized
                , rewardDescribable:AppRewardDescription(rewardTitle: "Constant Use of Apps Including All New", rewardShortTitle: "Yearly Apps License", rewardDescription: nil, rewardUnit: nil)
        )

        , AppCharge(type: .nonRenewingMonthlySubscription
                , reward: .rented
                , payment:PayForOneMonthAllApps.self
                , priceAmount: AmountObject.max
                , title:"1-Month Pass".localized
                , rewardDescribable:AppRewardDescription(rewardTitle: "A Month of Apps Including All New", rewardShortTitle: "1-Month Apps License", rewardDescription: nil, rewardUnit: nil)
        )
        , AppCharge(type: .nonRenewingYearlySubscription
                , reward: .rented, payment:PayForOneYearAllApps.self
                , priceAmount: AmountObject.max
                , title:"1-Year Pass".localized
                , rewardDescribable:AppRewardDescription(rewardTitle: "A Year of Apps Including All New", rewardShortTitle: "1-Year Apps License", rewardDescription: nil, rewardUnit: nil)
        )

    ], banker: AppChargeBanker.self)
}

//INFO: maintain like a black box
private class AppCharge: Charge {
    let type: ChargeType
    let reward: RewardType
    let payment:Payable.Type

    let priceAmount:Amount
    let title: String

    var description: String?
    lazy var rewardDescribable:RewardDescribable? = self //Auto Default

    init(type: ChargeType,
         reward: RewardType,
         payment:Payable.Type,
         priceAmount:Amount,
         title: String,
         description: String?=nil,
         rewardDescribable:RewardDescribable?=nil){

        self.type = type
        self.reward = reward
        self.payment = payment
        self.priceAmount = priceAmount
        self.title = title
        self.description = description

        //if custom defined
        if rewardDescribable != nil{
            self.rewardDescribable = rewardDescribable
        }
    }
}

private struct AppRewardDescription:RewardDescribable{
    private(set) var rewardTitle: String? = nil
    private(set) var rewardShortTitle: String? = nil
    private(set) var rewardDescription: String? = nil
    private(set) var rewardUnit: String? = nil
}

extension AppCharge: RewardDescribable{
    var rewardTitle:String? {
        switch (self.reward) {
        case .timeOfUses:
            if let unit = rewardUnit {
                return "%@ Day License".localizedFormatted(unit)
            }
        default:
            break
        }
        return nil
    }

    var rewardShortTitle:String? {
        switch (self.reward) {
        case .timeOfUses:
            if let unit = rewardUnit {
                return "%@ Day".localizedFormatted(unit)
            }
        default:
            break
        }

        return nil
    }

    var rewardDescription: String? {
        return nil
    }

    var rewardUnit:String?{
        switch (self.reward){
        case .timeOfUses:
            return (priceAmount.value * AppChargeBanker.Abs_TimeOfUses_Day).roundedString(toPlaces: 1, trimTrailingZeros: true)
        default:
            return nil
        }
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

        print("initializeBank:appShortVersionDescription: ",appShortVersionDescription)

        switch appShortVersionDescription{
            case .first:
                //INFO: give tutorial balance 3 days
                if let welcomeCharge = self.registeredCharges.first(where:{ charge in
                    return charge.type == .welcomeFreeTrial
                }){
                    assert(initialBalance.value == 0, "User installs the app firstly but why balance is not 0?")
                    createOrReplaceReceipt(for:welcomeCharge)
                }

            case .new, .skippedNew:
                //INFO: expired on new version
                for r in receiptStorage.receipts where type(of: self).ChargeTypesAvailableOnlyCurrentVersion.contains(r.value.type){
                    receiptStorage.removeReceipt(r.key)
                }

            case .reversed, .unhandled:
                //INFO: wrong binary protection
                assert(false, "Wrong version direction. Install new one.")
                for r in receiptStorage.receipts{
                    receiptStorage.removeReceipt(r.key)
                }

            default:
#if DEBUG
//            for r in receiptStorage.receipts{
//                receiptStorage.removeReceipt(r.key)
//            }
#endif
                break
        }

        print("[i] \(String(describing: type(of: self))) Initializd. Balance: ", initialBalance.value)

        return self.synchronizeBalance(balance:initialBalance)
    }

    func didInitializeBank(balance: Amount) {
        verifyReceipts()
    }

    private func verifyReceipts(){
        let currentQueue = DispatchQueue.current

        DispatchQueue.global(qos: .background).async{
            let asyncSignal = AsyncSignal()

            for c in self.registeredCharges{

                if let vReceipt = self.receiptStorage.getReceipt(for: c)
                    , let vPayable = c.payment as? VerifiablePayable.Type {

                    if let vResult = vPayable.init().verify(asyncSignal){

                        // Detected InValid Receipt
                        if vResult == false{
                            currentQueue.async(flags:.barrier){
                                self.receiptStorage.removeReceipt(vReceipt.uuid)
                            }
                            print("[i] INFO: Receipt Verification SUCCEED -> InValid Receipt: \(String(describing: vPayable))")
                        }else{
                            print("[i] INFO: Receipt Verification SUCCEED -> Valid Receipt: \(String(describing: vPayable))")
                        }
                    }else{
                        print("[!] WARNING: Receipt Verification FAILED for \(String(describing: vPayable))." +
                                "\n1. Check network status or Validator's URL whether is for production (https://buy.itunes.apple.com/verifyReceipt) or sandbox (https://sandbox.itunes.apple.com/verifyReceipt). " +
                                "\n2. Check 'NSAppTransportSecurity' in Info.plist for 'apple.com' \n ")
                    }
                }

            }
        }
    }

    private func createOrReplaceReceipt(for charge: Charge){
        var receipt = ChargeableReceipt(charge: charge, bankerVersion: AppChargeBanker.version)
        receipt.dateData = Date()

        if let existedReceiptItem = receiptStorage.receipts.first(where:{ key, value in
            value.isFrom(charge: charge)
        }){
            receiptStorage.removeReceipt(existedReceiptItem.value.uuid)
            receiptStorage.addReceipt(receipt)

        }else{
            receiptStorage.addReceipt(receipt)
        }

        assert(receiptStorage.receipts.filter({ key, value in value.isFrom(charge: charge) }).count==1, "only one receipt is allowed for: createOrReplaceReceipt")

    }

    @discardableResult
    private func synchronizeBalance(balance: Amount) -> Amount{
        var removingReceipts = Set<ChargeableReceipt>()
        let syncDate = Date()

        for (_, receipt) in receiptStorage.receipts { //TODO: improve performance - o.n -> o.1 avg.

            guard let charge = registeredCharges.first(where:{ charge in charge.identifier == receipt.chargeableIdentifier }) else {
                continue
            }

            //deprecated
            if receipt.type == .deprecated || receipt.reward == .deprecated{
                removingReceipts.insert(receipt)
                continue
            }

            switch receipt.reward{
                case .nonBlockOfUses, .owned, .rented:
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
        }

        self.receiptStorage.commit()

        let balance = AmountObject(value:receiptStorage.balanceAmountValue)
        print("[i] Balance:", balance.value)
        return balance
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
        papLog.charge.paid(type: charge.type)
    }

    func didDeclineDeposit(for charge: Charge) {
        papLog.charge.unpaid(type: charge.type)
    }
}
