//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
/*
INFO: Rules of Product IDs
WARNING: MUST use string literal-permanent, Avoid using Swift code literal to prevent changes from refactoring.

- Format:  pap
           -{bundle id | app class}
           -{PURCHASE CODE}
           -{PERIOD CODE}
           -{reward type}

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

e.g. Converter specific -> pap-{com.stells.pap.converter}-*
e.g. All CApp class -> pap-capp-*

*/

// All Apps
struct AllTimeAllAppsPayment: NonConsumablePurchasingPayable {
    static let product: StorePayableProduct = StoreProduct(identifier: "pap-xapp-NC-P-owned")
}

struct OneMonthAllAppsPayment: NonRenewingSubscribingPayable {
    static let product: StorePayableProduct = StoreProduct(identifier: "pap-xapp-NR-M-owned")
}

struct OneYearAllAppsPayment: NonRenewingSubscribingPayable {
    static let product: StorePayableProduct = StoreProduct(identifier: "pap-xapp-NR-Y-owned")
}

struct MonthlyAllAppsPayment: AutoRenewableSubscribingPayable {
    static let product: StorePayableProduct = StoreProduct(identifier: "pap-xapp-RN-M-owned")
}

struct YearlyAllAppsPayment: AutoRenewableSubscribingPayable {
    static let product: StorePayableProduct = StoreProduct(identifier: "pap-xapp-RN-Y-owned")
}

// 1-App
struct AllTimeAppPayment<T:App>: NonConsumablePurchasingPayable{
    static var product: StorePayableProduct{
        return StoreProduct(identifier: "pap-\(T.info.identifier)-NC-P-owned")
    }
}

struct MonthlyAppPayment<T:App>: AutoRenewableSubscribingPayable{
    static var product: StorePayableProduct{
        return StoreProduct(identifier: "pap-\(T.info.identifier)-RN-M-owned")
    }
}

struct YearlyAppPayment<T:App>: AutoRenewableSubscribingPayable{
    static var product: StorePayableProduct{
        return StoreProduct(identifier: "pap-\(T.info.identifier)-RN-Y-owned")
    }
}

struct OneMonthAppPayment<T:App>: NonRenewingSubscribingPayable{
    static var product: StorePayableProduct{
        return StoreProduct(identifier: "pap-\(T.info.identifier)-NR-M-owned")
    }
}

struct OneYearAppPayment<T:App>: NonRenewingSubscribingPayable{
    static var product: StorePayableProduct{
        return StoreProduct(identifier: "pap-\(T.info.identifier)-NR-Y-owned")
    }
}



// https://developer.apple.com/documentation/storekit/in-app-purchase/offering-introductory-pricing-in-your-app
// >= iOS 11.2
// https://developer.apple.com/documentation/storekit/skproduct/2936878-introductoryprice?changes=latest-minor
// Consider - 7day / 1 Month Free Trial
