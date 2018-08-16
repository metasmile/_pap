//
// Created by BLACKGE?NE ???on 24?.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit


extension AppCenter{
    static let charge:ChargeManager = AppChargeManager.initialize()

    //INFO: Priority is critical.
    static var isPaidInCurrentContext:Bool{
        return paidChargeableTypeInCurrentContext != nil
    }

    //INFO: Priority is critical.
    static var paidChargeableTypeInCurrentContext: ChargeableKey?{
        // Priority 1 - Owned - paid
        if let charge = charge.getChargesHasPaidOwned().nilEmpty?.first{
            return charge
        }

        let paidCharges = charge.getChargesHasPaid()

        // Priority 2 - localCharge - paid
        if let chargeableCurrent = self.default.current as? ChargeableApp.Type{
            let paidChargesIDs = Set(paidCharges.map{ $0.identifier })
            let localChargeIdSet = Set(chargeableCurrent.localCharges.map{ $0.identifier })

            return localChargeIdSet.intersection(paidChargesIDs).count > 0
                    ? chargeableCurrent.localCharges.first
                    : nil
        }

        // Priority 3 - remaining balance - for free apps.
        return charge.bank.balanceValue > 0
                ? paidCharges.first
                : nil
    }
}

private final class AppChargeManager: ChargeManager{

    fileprivate static func initialize() -> AppChargeManager {
        let localChargesOfEachApps = AppCenter.default.apps(by: AppQuery.default).compactMap { appType -> [Charge]? in
            return (appType as? ChargeableApp.Type)?.localCharges
        }.reduce([], +).nilEmpty
        
        let rootCharges = [
            // Initial
            AppCharge(type: .welcomeFreeTrial
                    , reward: .timeOfUses
                    , payment:PayOfInitialTutorial.self
                    , priceAmount: AmountObject(value:AppChargeBanker.InitialTutorial_TimeOfUses_Day/AppChargeBanker.Abs_TimeOfUses_Day)
                    , describable: AppChargeDescription(title:"Welcome Free Trial Pack".localized, description: nil, iconImage: nil) 
            )

            // Engagement
            , AppCharge(type: .onPromptRating
                    , reward: .nonBlockOfUses
                    , payment:PayOnPromptRating.self
                    , priceAmount: AmountObject(value:0.0)
                    , describable: AppChargeDescription(title:"Give A Rating".localized, description: nil, iconImage: nil) 
            )

            , AppCharge(type: .inStoreRating
                    , reward: .nonBlockOfUses
                    ,  payment:PayInAppStoreRating.self
                    , priceAmount: AmountObject(value:0.0)
                    , describable: AppChargeDescription(title:"Write A Review".localized, description: nil, iconImage: nil) 
            )

            , AppCharge(type: .socialShare
                    , reward: .timeOfUses
                    , payment:PayOnSocialShare.self
                    , priceAmount: AmountObject(value:0.5)
                    , describable: AppChargeDescription(title:"Share This App".localized, description: nil, iconImage: nil) 
            )

            , AppCharge(type: .feedback
                    , reward: .timeOfUses
                    , payment:PayOnFeedback.self
                    , priceAmount: AmountObject(value:0.5)
                    , describable: AppChargeDescription(title:"Send Us Feedback".localized, description: nil, iconImage: nil) 
            )

            // Store Purchase
            , AppCharge(type: .nonConsumablePurchase
                    , reward: .owned, payment: AllTimeAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"Purchase All At Once".localized, description: nil, iconImage: nil) 
                    , rewardDescribable:AppRewardDescription(title: "Permanent Use of All Apps And New", shortTitle: "Permanent Apps License", description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .renewableMonthlySubscription
                    , reward: .rented, payment: MonthlyAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"Monthly Pass".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "Constant Use of All Apps And New", shortTitle: "Yearly Apps License", description: nil, unit: nil, iconImage: nil)
            )
            , AppCharge(type: .renewableYearlySubscription
                    , reward: .rented
                    , payment: AnnualAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"Annual Pass".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "Constant Use of All Apps And New", shortTitle: "Yearly Apps License", description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .nonRenewingMonthlySubscription
                    , reward: .rented
                    , payment: OneMonthAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"1-Month Pass".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "A Month Use of All Apps And New", shortTitle: "1-Month Apps License", description: nil, unit: nil, iconImage: nil)
            )
            , AppCharge(type: .nonRenewingYearlySubscription
                    , reward: .rented, payment: OneYearAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"1-Year Pass".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "A Year Use of All Apps And New", shortTitle: "1-Year Apps License", description: nil, unit: nil, iconImage: nil)
            )
        ]

        return AppChargeManager(charges:rootCharges + (localChargesOfEachApps ?? []), banker: AppChargeBanker.self)
    }
}

struct AppChargeDescription:ChargeDescribable{
    let title: String
    var description: String? = nil
    var iconImage: ImageSourceable? = nil
}

struct AppRewardDescription:RewardDescribable{
    var title: String? = nil
    var shortTitle: String? = nil
    var description: String? = nil
    var unit: String? = nil
    var iconImage: ImageSourceable? = nil
}

class AppCharge: Charge {
    private(set) var type: ChargeType
    private(set) var reward: RewardType
    private(set) var payment:Payable.Type
    private(set) var priceAmount:Amount
    private(set) var describable: ChargeDescribable
    private(set) lazy var rewardDescribable:RewardDescribable? = DefaultRewardDescribable(charge:self)

    init(type: ChargeType,
         reward: RewardType,
         payment:Payable.Type,
         priceAmount:Amount,
         describable:ChargeDescribable,
         rewardDescribable:RewardDescribable?=nil){

        self.type = type
        self.reward = reward
        self.payment = payment
        self.priceAmount = priceAmount
        self.describable = describable
        //if custom defined
        if rewardDescribable != nil{
            self.rewardDescribable = rewardDescribable
        }
        validate()
    }

    private func validate(){
        if self.reward.isNonConsumable{
            if false == self.priceAmount.isEqual(to: AmountObject.min){
                assert(false, "Reward isNonConsumable priceAmount is not required")
                self.priceAmount = AmountObject.min
            }
        }
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        /*
            Verify Payment
        */
        if let payable = payment as? VerifiablePayable.Type {

            if let result = payable.init().verify(asyncSignal){
                // Detected InValid Receipt
#if DEBUG
                if result == false{
                    print("[i] INFO: Receipt Verification SUCCEED -> InValid Receipt: \(String(describing: payable))")
                }else{
                    print("[i] INFO: Receipt Verification SUCCEED -> Valid Receipt: \(String(describing: payable))")
                }
#endif
                return result

            } else{
#if DEBUG
                print("[!] WARNING: Receipt Verification FAILED for \(String(describing: payable)).")

                if payment is StorePayable{
                    print("[!] WARNING: 1. Check network status or Validator's URL whether is for production (https://buy.itunes.apple.com/verifyReceipt) or sandbox (https://sandbox.itunes.apple.com/verifyReceipt). " +
                            "\n2. Check 'NSAppTransportSecurity' in Info.plist for 'apple.com' \n " +
                            "\n3. Check Product Id(Not Registered or Deprecated)/Type(Mismatched) on AppStore connect \n "
                    )
                }
#endif
            }
        }

        return nil
    }

    private struct DefaultRewardDescribable:RewardDescribable {
        let charge:Charge
        init(charge:Charge){
            self.charge = charge
        }

        var title:String? {
            switch (charge.reward) {
            case .timeOfUses:
                if let unit = unit {
                    return "%@ Day License".localizedFormatted(unit)
                }
            default:
                break
            }
            return nil
        }

        var shortTitle:String? {
            switch (charge.reward) {
            case .timeOfUses:
                if let unit = unit {
                    return "%@ Day".localizedFormatted(unit)
                }
            default:
                break
            }

            return nil
        }

        var description: String? {
            return nil
        }
        var iconImage: ImageSourceable? {
            return nil
        }

        var unit:String?{
            switch (charge.reward){
            case .timeOfUses:
                return (charge.priceAmount.value * AppChargeBanker.Abs_TimeOfUses_Day).roundedString(toPlaces: 1, trimTrailingZeros: true)
            default:
                return nil
            }
        }
    }
}

extension AppCharge{
    static func createLocalAppCharge<A:App>(of app:A.Type, as chargeType:ChargeType, description:RewardDescribable?=nil) -> Charge?{
        var payable:Payable.Type?
        switch chargeType{
            case .none:
                payable = FreeAppPayment<A>.self
            case .nonConsumablePurchase:
                payable = AllTimeAppPayment<A>.self
            case .nonRenewingMonthlySubscription:
                payable = OneMonthAppPayment<A>.self
            case .nonRenewingYearlySubscription:
                payable = OneYearAppPayment<A>.self
            case .renewableMonthlySubscription:
                payable = MonthlyAppPayment<A>.self
            case .renewableYearlySubscription:
                payable = YearlyAppPayment<A>.self
            default:
                break
        }

        guard let chargingPayable = payable else{
            assert(false, "Given type \(String(describing: payable)) is not supported for App.")
            return nil
        }

        let rewardDescribable:RewardDescribable? = description ?? [
            ChargeType.nonConsumablePurchase: AppRewardDescription(
                    title: "Permanent Use And All New Updates".localized,
                    shortTitle: "Permanent Single App License",
                    description: nil,
                    unit: nil,
                    iconImage: app.info.iconBundleName
            )
            , ChargeType.none: AppRewardDescription(
                    title: "Free Use For All".localized,
                    shortTitle: "Permanent Single App License",
                    description: nil,
                    unit: nil,
                    iconImage: app.info.iconBundleName
            )
        ][chargeType]

        return AppCharge(type: chargeType
                , reward: .localOwned
                , payment: chargingPayable
                , priceAmount: AmountObject.min
                , describable: AppChargeDescription(title:"Purchase %@".localizedFormatted(app.info.displayName), description: nil, iconImage: nil) 
                , rewardDescribable: rewardDescribable
        )
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

    private let registeredChargesIdentifierSet:[String:Charge]
    private let registeredCharges:[Charge]

    init(registeredCharges: [Charge]) {
        self.registeredCharges = registeredCharges
        self.registeredChargesIdentifierSet = self.registeredCharges.dictionary { $0.identifier }

        #if DEBUG
        for c in self.registeredCharges{
            print("[i] Registered Charge at \(String(describing: AppChargeBanker.self)), localIdentifier :", c.identifier)
        }
        #endif
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

        return self.synchronizeReceipts(balance:initialBalance)
    }

    func didInitializeBank(balance: Amount) {
        synchronizeReceiptsAsyncByCharges()
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

    private func synchronizeReceiptsAsyncByCharges(){
        let currentQueue = DispatchQueue.current

        DispatchQueue.global(qos: .background).async{
            let asyncSignal = AsyncSignal()

            for c in self.registeredCharges{
                guard let vReceipt = self.receiptStorage.getReceipt(for: c) else {
                    continue
                }

                if let verifiedResult = c.verify(asyncSignal), verifiedResult == false{
                    currentQueue.async(flags:.barrier){
                        self.receiptStorage.removeReceipt(vReceipt.uuid)
                    }
                    continue
                }
            }
        }
    }


    @discardableResult
    private func synchronizeReceipts(balance: Amount) -> Amount{
        let hasOwned = receiptStorage.receipts.values.contains { receipt in receipt.reward.isOwned }

        var removingReceipts = Set<ChargeableReceipt>()

        for (_, receipt) in receiptStorage.receipts {
            guard let charge = registeredChargesIdentifierSet[receipt.chargeableIdentifier] else {
                continue
            }

            // Invalid or already consumed receipt
            if receipt.verify() == false{
                removingReceipts.insert(receipt)
                continue
            }

            // try consumed and then, this receipt was empty if it currently not owned.
            if hasOwned == false && receipt.reward.isNonConsumable == false{
                if !tryConsume(for: receipt, of: charge){
                    removingReceipts.insert(receipt)
                }
                continue
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

    //INFO: return -> true: Remained, so consumed successfully.
    //                false: does not remain any consumable amount
    private func tryConsume(for receipt:ChargeableReceipt, of charge: Charge) -> Bool{
        if receipt.reward.isNonConsumable {
            assert(false, "[!] ERROR: 'tryConsume' has called, but receipt \(receipt) is nonConsumable.")
            return false
        }

        let syncDate = Date()

        switch receipt.reward{
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

                        return true
                    }
                }
            default:
                assert(false, "[!] WARNING: \(receipt.reward) handling is not implemented yet.")
        }

        return false
    }

    func getReceipt(for chargeable: Chargeable) -> ChargeableReceipt? {
        return receiptStorage.getReceipt(for: chargeable)
    }

    func synchronizeBalanceValue(balance: Amount) -> Amount {
        return synchronizeReceipts(balance:balance)
    }

    func willSaveDeposit(forPriceAmountOf charge: Charge, balance: Amount) -> Amount? {
        createOrReplaceReceipt(for: charge)
        synchronizeReceipts(balance:balance)

        return charge.priceAmount
    }

    func didSaveDeposit(for charge: Charge, balance: Amount) {
        papLog.charge.paid(charge: charge)
    }

    func didDeclineDeposit(for charge: Charge) {
        papLog.charge.unpaid(charge: charge)
    }
}
