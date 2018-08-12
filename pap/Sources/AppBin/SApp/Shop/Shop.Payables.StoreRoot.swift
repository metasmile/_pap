//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
/*
INFO: Rules of Product IDs

- Format: {pap(Photo Apps)}_{bundle id suffix(pap.{*}) or app class including BApp,..*App}_{product ref. name}_{charge type}_{reward type}
e.g. Converter specific -> pap_converter_*
e.g. All CApp class -> pap_capp_*

- Code: Following string literal(==rawValue) is product ID
*/
private enum StoreRootProducts: String, StorePayableProduct {
    case pap_xapp_AllTimeAllApps_nonConsumablePurchase_owned

    case pap_xapp_OneMonthAllApps_nonRenewingMonthlySubscription_owned
    case pap_xapp_OneYearAllApps_nonRenewingYearlySubscription_owned

    case pap_xapp_MonthlyAllApps_renewableMonthlySubscription_owned
    case pap_xapp_YearlyAllApps_renewableYearlySubscription_owned

    var identifier:String{
        return self.rawValue
    }
}

struct PayForAllTimeAllApps: NonConsumablePurchasingPayable {
    static var product: StorePayableProduct{
        return StoreRootProducts.pap_xapp_AllTimeAllApps_nonConsumablePurchase_owned
    }
}

struct PayForOneMonthAllApps: NonRenewingSubscribingPayable {
    static var product: StorePayableProduct {
        return StoreRootProducts.pap_xapp_OneMonthAllApps_nonRenewingMonthlySubscription_owned
    }
}

struct PayForOneYearAllApps: NonRenewingSubscribingPayable {
    static var product: StorePayableProduct {
        return StoreRootProducts.pap_xapp_OneYearAllApps_nonRenewingYearlySubscription_owned
    }
}

struct PayForMonthlyAllApps: AutoRenewableSubscribingPayable {
    static var product: StorePayableProduct {
        return StoreRootProducts.pap_xapp_MonthlyAllApps_renewableMonthlySubscription_owned
    }
}

struct PayForYearlyAllApps: AutoRenewableSubscribingPayable {
    static var product: StorePayableProduct {
        return StoreRootProducts.pap_xapp_YearlyAllApps_renewableYearlySubscription_owned
    }
}



// https://developer.apple.com/documentation/storekit/in_app_purchase/offering_introductory_pricing_in_your_app
// >= iOS 11.2
// https://developer.apple.com/documentation/storekit/skproduct/2936878-introductoryprice?changes=latest_minor
// Consider - 7day / 1 Month Free Trial
