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

        e.g. Converter specific -> pap_{com.stells.pap.converter}_*
        e.g. All CApp class -> pap_capp_*

- Rules of Subscription Group
        - Format: pap
                  _{bundle id | app class}
*/

// All Apps
struct AllTimeAllAppsPayment: NonConsumablePurchasingPayable {
    static let product = StoreProduct(identifier: "pap_xapp_NC_P_owned", subscriptionPeriod: nil)
}

struct MonthlyAllAppsPayment: AutoRenewableSubscribingPayable {
    static let product = StoreProduct(identifier: "pap_xapp_RN_M_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .month))
}

struct YearlyAllAppsPayment: AutoRenewableSubscribingPayable {
    static let product = StoreProduct(identifier: "pap_xapp_RN_Y_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .year))
}

struct OneMonthAllAppsPayment: NonRenewingSubscribingPayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_1M_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .month))
}

struct ThreeMonthsAllAppsPayment: NonRenewingSubscribingPayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_3M_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 3, unit: .month))
}

struct SixMonthsAllAppsPayment: NonRenewingSubscribingPayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_6M_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 6, unit: .month))
}

struct OneYearAllAppsPayment: NonRenewingSubscribingPayable {
    static let product = StoreProduct(identifier: "pap_xapp_NR_1Y_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .year))
}


// 1_App
struct AllTimeAppPayment<T:App>: NonConsumablePurchasingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_NC_P_owned", subscriptionPeriod: nil)
    }
}

struct MonthlyAppPayment<T:App>: AutoRenewableSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_RN_M_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .month))
    }
}

struct YearlyAppPayment<T:App>: AutoRenewableSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_RN_Y_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .year))
    }
}

struct OneMonthAppPayment<T:App>: NonRenewingSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_NR_M_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .month))
    }
}

struct OneYearAppPayment<T:App>: NonRenewingSubscribingPayable{
    static var product: StoreProduct{
        return StoreProduct(identifier: "pap_\(T.info.identifier)_NR_Y_rented", subscriptionPeriod: StoreProduct.SubscriptionPeriod(numberOfUnits: 1, unit: .year))
    }
}



// https://developer.apple.com/documentation/storekit/in-app-purchase/offering-introductory-pricing-in-your-app
// >= iOS 11.2
// https://developer.apple.com/documentation/storekit/skproduct/2936878-introductoryprice?changes=latest-minor
// Consider - 7day / 1 Month Free Trial
