//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
/*
WARNING: MUST use string literal-permanent, Avoid using Swift code literal to prevent changes from refactoring.

- Rules of Product IDs
        - Format:  pap
                   _{bundle id | app class}
                   _{PURCHASE CODE}
                   _{PERIOD CODE}
                   _{reward type}
                   _{version (Int)}? (Optional)

        - PURCHASE CODE
            NC - NonConsumable
            CC - Consumable
            NR - NonRenewable
            RN - Renewable

        - PERIOD CODE
            P: Purchase once
            Y: Yearly
            M: Monthly
            W: Weekly
            [1-N]Y: N year - nonRenewing
            [1-11]M - N Month - nonRenewing

        e.g. Converter specific -> pap_{com.stells.batch.converter}_*
        e.g. All CApp class -> pap_capp_*

- Rules of Subscription Group
        - Format: pap
                  _{bundle id | app class}
*/

private let StoreLegalDescription = "Payment will be charged to iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Your account will be charged for renewal within 24-hours prior to the end of the current period, and identify the cost of the renewal. Subscriptions may be managed by the user and auto-renewal may be turned off by going to the user’s Account Settings after purchase. Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription to that publication, where applicable."

// All Apps
struct AllTimeAllAppsPayment: NonConsumablePurchasingPayable, RelativePayable {
    static let product = StoreProduct(identifier: "pap_xapp_NC_P_owned", subscriptionPeriod: nil, legalInfo: nil)

    static var superPayables: HashSet<Payable.Type> {
        return [SecretCodeProgramPayment<PermanentVIPSecretCodeProgram>.self].hashSet
    }
}


struct MonthlyAllAppsPayment: AutoRenewableSubscribingPayable, RelativePayable {
    static let product = StoreProduct(identifier: "pap_xapp_RN_M_rented", subscriptionPeriod: Period(numberOfUnits: 1, unit: .month), legalInfo:(notice:StoreLegalDescription,termsOfUse:URL(string:papStrings.info.terms.url), privacyPolicy:URL(string:papStrings.info.privacy.url)))
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }
}

struct YearlyAllAppsPayment: AutoRenewableSubscribingPayable, RelativePayable {
    static let product = StoreProduct(identifier: "pap_xapp_RN_Y_rented_2", subscriptionPeriod: Period(numberOfUnits: 1, unit: .year), legalInfo:(notice:StoreLegalDescription,termsOfUse:URL(string:papStrings.info.terms.url), privacyPolicy:URL(string:papStrings.info.privacy.url)))
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }
}

struct OneMonthAllAppsPayment: NonRenewingSubscribingPayable, RelativePayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_1M_rented", subscriptionPeriod: Period(numberOfUnits: 1, unit: .month), legalInfo: nil)
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }
}

struct ThreeMonthsAllAppsPayment: NonRenewingSubscribingPayable, RelativePayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_3M_rented", subscriptionPeriod: Period(numberOfUnits: 3, unit: .month), legalInfo: nil)
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }
}

struct SixMonthsAllAppsPayment: NonRenewingSubscribingPayable, RelativePayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_6M_rented", subscriptionPeriod: Period(numberOfUnits: 6, unit: .month), legalInfo: nil)
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }
}

struct OneYearAllAppsPayment: NonRenewingSubscribingPayable, RelativePayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_1Y_rented_1", subscriptionPeriod: Period(numberOfUnits: 1, unit: .year), legalInfo: nil)
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }
}


// 1_App

struct AllTimeAppPayment<T:App>: NonConsumablePurchasingPayable, TrialablePayable, RelativePayable{
    static var superPayables: HashSet<Payable.Type> {
        return self.defaultSuperPayables
    }

    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_NC_P_owned", subscriptionPeriod: nil, legalInfo: nil)
    }

    static var trialTimeLength: TimeInterval {
        return papTimeInterval.ofAllTimeAppPaymentTrialTimeLength
    }
}

struct MonthlyAppPayment<T:App>: AutoRenewableSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_RN_M_rented", subscriptionPeriod: Period(numberOfUnits: 1, unit: .month), legalInfo: (notice:StoreLegalDescription,termsOfUse:URL(string:papStrings.info.terms.url), privacyPolicy:URL(string:papStrings.info.privacy.url)))
    }
}

struct YearlyAppPayment<T:App>: AutoRenewableSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_RN_Y_rented", subscriptionPeriod: Period(numberOfUnits: 1, unit: .year), legalInfo: (notice:StoreLegalDescription,termsOfUse:URL(string:papStrings.info.terms.url), privacyPolicy:URL(string:papStrings.info.privacy.url)))
    }
}

struct OneMonthAppPayment<T:App>: NonRenewingSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_NR_M_rented", subscriptionPeriod: Period(numberOfUnits: 1, unit: .month), legalInfo: nil)
    }
}

struct OneYearAppPayment<T:App>: NonRenewingSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_NR_Y_rented", subscriptionPeriod: Period(numberOfUnits: 1, unit: .year), legalInfo: nil)
    }
}



// https://developer.apple.com/documentation/storekit/in-app-purchase/offering-introductory-pricing-in-your-app
// >= iOS 11.2
// https://developer.apple.com/documentation/storekit/skproduct/2936878-introductoryprice?changes=latest-minor
// Consider - 7day / 1 Month Free Trial
