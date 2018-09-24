//
// Created by ?BLACKGE?NE ???on 24?.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import PropertyKit


extension AppCenter{
    static let charge:ChargeManager = AppChargeManager.initialize()

    static var isPaidInCurrentContext:Bool{
        return paidChargeableTypeInCurrentContext != nil
    }

    //POLICY: VIP == '.owned' (permanently)
    static var isPaidAsVIPInCurrentContext:Bool{
        return charge.getChargesPaid().contains { $0.reward == .owned }
        //this is '.owned' specific. different from 'isOwned'
    }

    //POLICY: RewardType.\isOwned == '.owned/.rented'
    static var isPaidAsOwnedInCurrentContext:Bool{
        return charge.getChargesPaid().contains { $0.reward.isOwned }
    }

    //CRITICAL: Priority ordering
    static var paidChargeableTypeInCurrentContext: Chargeable?{
        // Priority 1 - Owned - paid
        if let charge = charge.getChargesPaidOwned().nilEmpty?.first{
            return charge
        }

        let paidCharges = charge.getChargesPaid()

        // Priority 2 - localCharge - paid
        if let chargeableCurrent = self.default.current as? ChargeableApp.Type{
            let paidChargesIDs = Set(paidCharges.map{ $0.identifier })
            let localChargeIdSet = Set(chargeableCurrent.localCharges.map{ $0.identifier })

            return localChargeIdSet.intersection(paidChargesIDs).count > 0
                    ? chargeableCurrent.localCharges.first
                    : nil
        }

        // Priority 3 - remaining balance - for free apps.
        if charge.bank.balanceValue > 0{
            return paidCharges.filter({ $0.reward.isNonConsumable == false }).first
        }

        // Priority 4 - nonConsumable charges
        if let chargeWithPredefinedPriorReward = paidCharges.first(where:{
            // Priority 4 - 1: blockOfUses
            $0.reward == .blockOfUses

        }) {
            return chargeWithPredefinedPriorReward
        }

        return nil
    }
}

private final class AppChargeManager: ChargeManager{

    fileprivate static func initialize() -> AppChargeManager {
        let localChargesOfEachApps = AppCenter.default.apps(by: AppQuery.default).compactMap { appType -> [Charge]? in
            return (appType as? ChargeableApp.Type)?.localCharges
        }.reduce([], +).nilEmpty
        
        let rootCharges = [
            // System - Restore
            AppCharge(type: .none
                    , reward: .systemOwned
                    , payment: RestorePurchasesSystemPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"Restore All Purchases".localized, description: nil, iconImage: nil)
            )
            // Initial
            , AppCharge(type: .freeTrial
                    , reward: .timeOfUses
                    , payment: WelcomeTutorialPayment.self
                    , priceAmount: AmountObject(value:AppChargeBanker.InitialTutorial_TimeOfUses_Day/AppChargeBanker.Abs_TimeOfUses_Day)
                    , describable: AppChargeDescription(title:"Welcome Free Pack".localized, description: nil, iconImage: nil)
            )

            , AppCharge(type: .onPromptRating
                    , reward: .nonBlockOfUses
                    , payment:InAppPromptRatingPayment.self
                    , priceAmount: AmountObject(value:0.0)
                    , describable: AppChargeDescription(title:"Give A Rating".localized, description: nil, iconImage: nil)
            )

//            , AppCharge(type: .inStoreRating
//                    , reward: .nonBlockOfUses
//                    ,  payment:InAppStoreRatingPayment.self
//                    , priceAmount: AmountObject(value:0.0)
//                    , describable: AppChargeDescription(title:"Write A Review".localized, description: nil, iconImage: nil)
//            )

            // Freecharge
            , AppCharge(type: .socialShare
                    , reward: .timeOfUses
                    , payment: FBShareTypeDownloadUrlPayment.self
                    , priceAmount: AmountObject(value:(0.1/3)*1)
                    , describable: AppChargeDescription(title:"Sharing on Facebook".localized, description: nil, iconImage: nil)
            )

            , AppCharge(type: .socialShare
                    , reward: .timeOfUses
                    , payment: FBShareTypeDownloadMessagerPayment.self
                    , priceAmount: AmountObject(value:(0.1/3)*7)
                    , describable: AppChargeDescription(title:"Sharing on Facebook Messenger".localized, description: nil, iconImage: nil)
            )

//            , AppCharge(type: .feedback
//                    , reward: .timeOfUses
//                    , payment: MailContactPayment<MailContactFeedbackType>.self
//                    , priceAmount: AmountObject(value:0.1)
//                    , describable: AppChargeDescription(title:"Send Us Feedback".localized, description: nil, iconImage: nil)
//            )

//            , AppCharge(type: .instantAdsViewingOnDemand
//                , reward: .timeOfUses
//                , payment: GADInterestialAdsViewingPayment<GADInterestialTypeTimeOfUses>.self
//                , priceAmount: AmountObject(value:0.1/3)
//                , describable: AppChargeDescription(title:"View Ads".localized, description: nil, iconImage: nil)
//            )

            , AppCharge(type: .secretCode
                    , reward: .timeOfUses
                    , payment: SecretCodeProgramPayment<SpecialGuestSecretCodeProgram>.self
                    , priceAmount: AmountObject(value:1)
                    , describable: AppChargeDescription(title:"Special Guest License".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "1-Month Use of Main and New Apps".localized, shortTitle: nil, description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .secretCode
                    , reward: .timeOfUses
                    , payment: SecretCodeProgramPayment<GuestUserSecretCodeProgram>.self
                    , priceAmount: AmountObject(value:(0.1/3)*14)
                    , describable: AppChargeDescription(title:"Guest User License".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "14-Day Use of Main and New Apps".localized, shortTitle: nil, description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .secretCode
                    , reward: .timeOfUses
                    , payment: SecretCodeProgramPayment<PromotionSecretCodeProgram>.self
                    , priceAmount: AmountObject(value:(0.1/3)*7)
                    , describable: AppChargeDescription(title:"Promotion License".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "7-Day Use of Main and New Apps".localized, shortTitle: nil, description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .secretCode
                    , reward: .timeOfUses
                    , payment: SecretCodeProgramPayment<YouAppSecretCodeProgram>.self
                    , priceAmount: AmountObject(value:1)
                    , describable: AppChargeDescription(title:"%@ Membership".localizedFormatted("YOU.app"), description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "1-Year Reuse of Main Apps".localized, shortTitle: nil, description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .instantAdsShowingAllowance
                    , reward: .blockOfUses
                    , payment: GADInterestialAdsViewingPayment<GADInterestialTypeBlockOfUses>.self
                    , priceAmount: AmountObject(value:0.0)
                    , describable: AppChargeDescription(title:"Activate Ads".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "Ongoing Use of All and New Main Apps".localized, shortTitle: nil, description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .urlVisiting
                    , reward: .timeOfUses
                    , payment: SNSEngagementPayment.self
                    , priceAmount: AmountObject(value:(0.1/3))
                    , describable: AppChargeDescription(title:"Visit Social Pages".localized, description: nil, iconImage: nil)
            )

            // Promotional
            , AppCharge(type: .secretCode
                    , reward: .owned, payment: SecretCodeProgramPayment<PermanentVIPSecretCodeProgram>.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"VIP Membership".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "Permanent Use of All and New Apps".localized, shortTitle: "Permanent Apps License", description: nil, unit: nil, iconImage: nil)
            )

            // Store Purchase
            , AppCharge(type: .nonConsumablePurchaseInAppStore
                    , reward: .owned, payment: AllTimeAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"Permanent Ownership".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "Permanent Use of All and New Apps".localized, shortTitle: "Permanent Apps License", description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .renewableMonthlySubscriptionInAppStore
                    , reward: .rented, payment: MonthlyAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"Monthly Membership".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "Ongoing Use of All and New Apps".localized, shortTitle: "Monthly Apps License", description: nil, unit: nil, iconImage: nil)
            )
            , AppCharge(type: .renewableYearlySubscriptionInAppStore
                    , reward: .rented
                    , payment: YearlyAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"Yearly Membership".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "Ongoing Use of All and New Apps".localized, shortTitle: "Yearly Apps License", description: nil, unit: nil, iconImage: nil)
            )

            , AppCharge(type: .nonRenewingMonthlySubscriptionInAppStore
                    , reward: .rented
                    , payment: OneMonthAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"1 Month Membership".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "1-Month Use of All and New Apps".localized, shortTitle: "1-Month Apps License", description: nil, unit: nil, iconImage: nil)
            )

//            , AppCharge(type: .nonRenewingYearlySubscriptionInAppStore
//                    , reward: .rented, payment: ThreeMonthsAllAppsPayment.self
//                    , priceAmount: AmountObject.min
//                    , describable: AppChargeDescription(title:"3 Months Membership".localized, description: nil, iconImage: nil)
//                    , rewardDescribable:AppRewardDescription(title: "3-Month Use of All and New Apps".localized, shortTitle: "3-Month Apps License", description: nil, unit: nil, iconImage: nil)
//            )

            , AppCharge(type: .nonRenewingYearlySubscriptionInAppStore
                    , reward: .rented, payment: SixMonthsAllAppsPayment.self
                    , priceAmount: AmountObject.min
                    , describable: AppChargeDescription(title:"6 Months Membership".localized, description: nil, iconImage: nil)
                    , rewardDescribable:AppRewardDescription(title: "6-Month Use of All and New Apps".localized, shortTitle: "6-Month Apps License", description: nil, unit: nil, iconImage: nil)
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
    private(set) var rewardDescribable:RewardDescribable?

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
        self.rewardDescribable = rewardDescribable ?? DefaultRewardDescribable(charge:self)
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
                    return "Main Apps Use of %@ Day".localizedFormatted(unit)
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
            return charge.priceAmount.getDefaultUnit(for: charge.reward)?.asString(roundTo: 1)
        }
    }
}

extension Amount{
    func getDefaultUnit(for reward:RewardType) -> Period?{
        switch (reward){
        case .timeOfUses:
            return Period(numberOfUnits: value * AppChargeBanker.Abs_TimeOfUses_Day, unit: .day)
        default:
            return nil
        }
    }
}

extension AppCharge{
    static func createLocalAppCharge<A:App>(of app:A.Type, as chargeType:ChargeType, description:RewardDescribable?=nil) -> Charge?{
        var payable:Payable.Type?
        switch chargeType{
            case .none:
                payable = FreeAppPayment<A>.self
            case .nonConsumablePurchaseInAppStore:
                payable = AllTimeAppPayment<A>.self
            case .nonRenewingMonthlySubscriptionInAppStore:
                payable = OneMonthAppPayment<A>.self
            case .nonRenewingYearlySubscriptionInAppStore:
                payable = OneYearAppPayment<A>.self
            case .renewableMonthlySubscriptionInAppStore:
                payable = MonthlyAppPayment<A>.self
            case .renewableYearlySubscriptionInAppStore:
                payable = YearlyAppPayment<A>.self
            default:
                assert(false, "Undefined chargeType to create LocalAppCharge \(chargeType)")
                break
        }

        guard let chargingPayable = payable else{
            assert(false, "Given type \(String(describing: payable)) is not supported for App.")
            return nil
        }

        let rewardDescribable:RewardDescribable? = description ?? [
            ChargeType.nonConsumablePurchaseInAppStore: AppRewardDescription(
                    title: "Permanent Use And All New Updates".localized,
                    shortTitle: "Permanent Single App License",
                    description: nil,
                    unit: nil,
                    iconImage: app.info.iconBundleName
            )
            , ChargeType.none: AppRewardDescription(
                    title: "Free Use And All New Updates".localized,
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
                , describable: AppChargeDescription(title:"%@ Ownership".localizedFormatted(app.info.displayName), description: nil, iconImage: nil)
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

    private lazy var receiptStorage = ChargeReceiptStorage(identifier: self.receiptStorageIdentifier, delegate: self)

    fileprivate static let Abs_TimeOfUses_DayTimeUnit:TimeInterval = papTimeInterval.ofTimeOfUsesDayTimeUnit
    fileprivate static let InitialTutorial_TimeOfUses_Day:TimeInterval = 3
    fileprivate static let Abs_TimeOfUses_Day:TimeInterval = 30
    fileprivate static let Abs_TimeOfUses_Time:TimeInterval = Abs_TimeOfUses_Day * Abs_TimeOfUses_DayTimeUnit

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

        switch Defaults.shared.shortVersionDescription{
            case .first:
                //INFO: give tutorial balance 3 days
                if let welcomeCharge = self.registeredCharges.first(where:{ charge in
                    return charge.type == .freeTrial
                }){
                    assert(initialBalance.value == 0, "User installs the app firstly but why balance is not 0?")
                    createOrReplaceReceipt(for:welcomeCharge)
                }

            case .new:
                //Not thing
                break

            case .reversed, .unhandled:
                //INFO: wrong binary protection
                print("[!] WARNING: Wrong version direction. Install new one. All receipts will be disposed.")
                for r in receiptStorage.receipts{
                    receiptStorage.removeReceipt(r.key)
                }

            default:
                //INFO: If it needs to reset all
                break
        }

        print("[i] \(String(describing: type(of: self))) Initializd. Balance: ", initialBalance.value)

        return self.synchronizeReceipts(balance:initialBalance)
    }

    func willInitializeBank(balance: Amount) {

    }

    func didInitializeBank(verifiedResults: ChargeableReceiptVerificationResult, balance: Amount) {
        var removedCount = 0
        for invalidReceipt in verifiedResults.invalid{
            if receiptStorage.hasReceipt(by: invalidReceipt.uuid){
                receiptStorage.removeReceipt(invalidReceipt.uuid)
                removedCount += 1
            }
        }

        if removedCount > 0{
            self.receiptStorage.commit()
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
    private func synchronizeReceipts(balance: Amount) -> Amount{
        let hasOwned = receiptStorage.receipts.values.contains { receipt in receipt.reward.isOwned }

        var removingReceipts = Set<ChargeableReceipt>()

        for (_, receipt) in receiptStorage.receipts {
            guard let charge = registeredChargesIdentifierSet[receipt.chargeableIdentifier] else {
                removingReceipts.insert(receipt)
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

    func synchronize(balance: Amount) -> Amount {
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

extension AppChargeBanker:ChargeReceiptStorageDelegate{
    internal func didInitialize(receipts: [String: ChargeableReceipt]) {
        for receipt in receipts.values{
            if let charge = registeredChargesIdentifierSet[receipt.chargeableIdentifier]{
                (charge.payment as? ReceiptObservablePayable.Type)?.didInitializeReceipt()
            }
        }
    }

    internal func didAdd(receipt: ChargeableReceipt) {
        if let charge = registeredChargesIdentifierSet[receipt.chargeableIdentifier]{
            (charge.payment as? ReceiptObservablePayable.Type)?.didAddReceipt()
        }
    }

    internal func didUpdate(receipt: ChargeableReceipt) {
        if let charge = registeredChargesIdentifierSet[receipt.chargeableIdentifier]{
            (charge.payment as? ReceiptObservablePayable.Type)?.didUpdateReceipt()
        }
    }

    internal func willRemove(receipt: ChargeableReceipt) {
        if let charge = registeredChargesIdentifierSet[receipt.chargeableIdentifier]{
            (charge.payment as? ReceiptObservablePayable.Type)?.willRemoveReceipt()
        }
    }

    internal func didCommit(changes: ChargeableReceiptChanges) {
        for committedReceipt in changes.added.union(changes.removed).union(changes.updated){
            if let charge = registeredChargesIdentifierSet[committedReceipt.chargeableIdentifier]{
                (charge.payment as? ReceiptObservablePayable.Type)?.didCommitReceipt()
            }
        }
    }
}
