//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import SwiftyStoreKit

//INFO: Following string literal(==rawValue) is product ID
//INFO: {pap(Photo Apps)}_{xapp(all app class including BApp,..XApp)}_{product ref. name}_{charge type}_{reward type}

private enum StoreProduct: String {
    case pap_xapp_AllTimeAllApps_nonConsumablePurchase_owned
    case pap_xapp_AllTimeOneApp_nonConsumablePurchase_owned

    case pap_xapp_OneMonthAllApps_nonRenewingMonthlySubscription_owned
    case pap_xapp_OneYearAllApps_nonRenewingYearlySubscription_owned

    case pap_xapp_MonthlyAllApps_renewableMonthlySubscription_owned
    case pap_xapp_YearlyAllApps_renewableYearlySubscription_owned

    var identifier:String{
        return self.rawValue
    }
}

struct PayForAllTimeAllApps:Payable, StorePayable {
    fileprivate static var storeProduct:StoreProduct{ return .pap_xapp_AllTimeAllApps_nonConsumablePurchase_owned }

    private(set) static var chargeable: Chargeable = AppChargeable(type: .nonConsumablePurchase, reward: .owned)
    private(set) static var payingLabel: String = "Purchase".localized

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).storeProduct.pay(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).storeProduct.verify(signal) {

            switch SwiftyStoreKit.verifyPurchase(
                    productId: r.product.identifier,
                    inReceipt: r.receipt) {

                case .purchased(let _):
                    return true
                default:
                    return false
            }
        }
        return nil
    }
}

struct PayForAllTimeOneApp:Payable, StorePayable {
    fileprivate static var storeProduct:StoreProduct{ return .pap_xapp_AllTimeOneApp_nonConsumablePurchase_owned }

    private(set) static var chargeable: Chargeable = AppChargeable(type: .nonConsumablePurchase, reward: .owned)
    private(set) static var payingLabel: String = "Purchase".localized

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).storeProduct.pay(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).storeProduct.verify(signal){

            switch SwiftyStoreKit.verifyPurchase(
                    productId: r.product.identifier,
                    inReceipt: r.receipt) {

                case .purchased(let _):
                    return true
                default:
                    return false
            }
        }
        return nil
    }
}

struct PayForOneMonthAllApps:Payable, StorePayable {
    fileprivate static var storeProduct:StoreProduct{ return .pap_xapp_OneMonthAllApps_nonRenewingMonthlySubscription_owned }

    private(set) static var chargeable: Chargeable = AppChargeable(type: .nonRenewingMonthlySubscription, reward: .owned)
    private(set) static var payingLabel: String = "Purchase".localized

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).storeProduct.pay(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).storeProduct.verify(signal){
            switch SwiftyStoreKit.verifySubscription(
                    ofType: .nonRenewing(validDuration: 60),
                    productId: r.product.identifier,
                    inReceipt: r.receipt){

                case .purchased(let _, let _):
                    return true
                default:
                    return false
            }
        }
        return nil
    }
}

struct PayForOneYearAllApps:Payable, StorePayable {
    fileprivate static var storeProduct:StoreProduct{ return .pap_xapp_OneYearAllApps_nonRenewingYearlySubscription_owned }

    private(set) static var chargeable: Chargeable = AppChargeable(type: .nonRenewingYearlySubscription, reward: .owned)
    private(set) static var payingLabel: String = "Purchase".localized

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).storeProduct.pay(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).storeProduct.verify(signal){

            switch SwiftyStoreKit.verifySubscription(
                    ofType: .nonRenewing(validDuration: 60),
                    productId: r.product.identifier,
                    inReceipt: r.receipt){

                case .purchased(let _, let _):
                    return true
                default:
                    return false
            }
        }
        return nil
    }
}

struct PayForMonthlyAllApps:Payable, StorePayable {
    fileprivate static var storeProduct:StoreProduct{ return .pap_xapp_MonthlyAllApps_renewableMonthlySubscription_owned }

    private(set) static var chargeable: Chargeable = AppChargeable(type: .renewableMonthlySubscription, reward: .owned)
    private(set) static var payingLabel: String = "Subscribe".localized

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).storeProduct.pay(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).storeProduct.verify(signal){

            switch SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: r.product.identifier,
                    inReceipt: r.receipt){

                case .purchased(let _, let _):
                    return true

                default:
                    return false
            }
        }
        return nil
    }
}


struct PayForYearlyAllApps:Payable, StorePayable {
    fileprivate static var storeProduct:StoreProduct{ return .pap_xapp_YearlyAllApps_renewableYearlySubscription_owned }

    private(set) static var chargeable: Chargeable = AppChargeable(type: .renewableYearlySubscription, reward: .owned)
    private(set) static var payingLabel: String = "Subscribe".localized

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).storeProduct.pay(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).storeProduct.verify(signal){
            switch SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: r.product.identifier,
                    inReceipt: r.receipt){

                case .purchased(let _, let _):
                    return true

                default:
                    return false
            }
        }
        return nil
    }
}

//INFO: Common Utility
extension StoreProduct {
    private static let ReceiptSecretKey = "pap-StoreProduct-ReceiptSecretKey-2C59B669-ADBD-462F-8C2A-CE452234BBE4"

    func pay(_ signal: AsyncWaitSignalable) -> Bool {

        var paid = false

        signal.begin()

        SwiftyStoreKit.purchaseProduct(self.identifier, atomically: true) { result in

            if case .success(let purchase) = result {
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                }
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }

                paid = true
                signal.end()
            }
        }

        signal.waitUntilEnd()
        return paid
    }

    static func restore(_ signal: AsyncWaitSignalable) -> [Purchase]?{
        var purchases:[Purchase]?

        signal.begin()

        SwiftyStoreKit.restorePurchases(atomically: true) { results in

            purchases = [Purchase]()

            for purchase in results.restoredPurchases {
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                } else if purchase.needsFinishTransaction {
                    // Deliver content from server, then:
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                purchases?.append(purchase)
            }
            signal.end()
        }

        signal.waitUntilEnd()

        return purchases?.nilEmpty
    }

    func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {

        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: type(of: self).ReceiptSecretKey)
        SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: completion)
    }

    func verify(_ signal: AsyncWaitSignalable) -> (product: StoreProduct, receipt:ReceiptInfo)? {

        var r:(product: StoreProduct, receipt:ReceiptInfo)?

        signal.begin()
        verifyReceipt { result in
            switch result {
                case .success(let receipt):
                    r = (product:self, receipt:receipt)

                case .error:
                    r = nil
            }
            signal.end()
        }
        signal.waitUntilEnd()
        return r
    }
}



// https://developer.apple.com/documentation/storekit/in_app_purchase/offering_introductory_pricing_in_your_app
// >= iOS 11.2
// https://developer.apple.com/documentation/storekit/skproduct/2936878-introductoryprice?changes=latest_minor
// Consider - 7day / 1 Month Free Trial