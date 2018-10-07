//
// Created by BLACKGENE on 8/12/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
//INFO: SwiftyStoreKit's dependency is ONLY LOCATED in this file.
import SwiftyStoreKit
import StoreKit
import UIKit

//INFO: pap specific Aug 10, 2018
private let papReceiptSecretKey = "791f81382c464b78803b22eba4fb2cde"
private let papNonRenewingValidDuration:TimeInterval = 60
#if DEBUG
private let papVerificationType = AppleReceiptValidator.VerifyReceiptURLType.sandbox
#else
private let papVerificationType = AppleReceiptValidator.VerifyReceiptURLType.production
#endif

//INFO: Fake implementation for App Store Connect's bug
//"These in-app purchases can’t be promoted on the App Store because your latest app binary doesn’t include the SKPaymentTransactionObserver method."
//https://stackoverflow.com/questions/46672653/skpaymenttransactionobserver-in-app-purchases-can-t-be-promoted-on-the-app-stor
public class __SKPaymentTransactionObserver: NSObject, SKPaymentTransactionObserver{
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {}
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool{
        return true
    }
}

//INFO: StorePayableCenter: Not recommended to use in Charge-ChargeBank-ChargeBanker family directly.
// Use in only in an ShopApp. When add Directory-Scoped access permission in swift?? huh.

struct StoreKitPayableCenter {

    //WARNING: Always must match with indicating status.
    private static var productIdentifierFromAppStoreForTransaction:String?

    static func configure() {

        func _getLocalChargeableAppBy(storeProductIdentifier:String) -> ChargeableApp.Type?{
            for app in AppCenter.default.apps() {
                if let cApp = app as? ChargeableApp.Type, Set(cApp.localCharges.compactMap({ ($0.payment as? StorePayable.Type)?.product.identifier })).contains(storeProductIdentifier) {
                    
                    return cApp
                }
            }
            return nil
        }

        /*
        Test URL of Sandbox

            Finder: itms-services://?action=purchaseIntent&bundleId=com.stells.pap&productIdentifier=pap_com.stells.pap.finder_NC_P_owned
            Converter: itms-services://?action=purchaseIntent&bundleId=com.stells.pap&productIdentifier=pap_com.stells.pap.converter_NC_P_owned
            1M: itms-services://?action=purchaseIntent&bundleId=com.stells.pap&productIdentifier=pap_xapp_NR_1M_rented
        */

        //INFO: Tap an IAP Product in AppStore -> App Download or Open -> Forwarding
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
            guard let charge = AppCenter.charge.getChargesHasStorePayable()[product.productIdentifier] else {
                return false
            }

            let currentIsShop = AppCenter.default.current == ShopApp.self

            DispatchQueue.main.async{
                let localChargeableApp = _getLocalChargeableAppBy(storeProductIdentifier:product.productIdentifier)

                if currentIsShop {
                    AppCenter.default.currentInstanceAs(ShopApp.self)?.sourceAppType = localChargeableApp
                    AppCenter.default.currentInstanceAs(ShopApp.self)?.reloadProductItems()

                }else{
                    var options:AppLaunchOptions?
                    if localChargeableApp != nil{
                        var o = [AppLaunchOptionsKey:Any]()
                        o[.ShopCallerAppType] = localChargeableApp
                        options = AppLaunchOptions(options: o)
                    }
                    AppCenter.default.openApp(identifier: ShopApp.info.identifier, options: options)
                }
            }

            // if super payable already paid
            if let superPayables = (charge.payment as? RelativePayable.Type)?.superPayables{
                for p in superPayables where AppCenter.charge.isPaid(payable: p.element){
                    return false
                }
            }

            // if self payable already paid
            if AppCenter.charge.isPaid(charge: charge){
                return false
            }

            //reserve identifier if only unpaid product
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (currentIsShop ? 0.0 : 1.0)) {
                AppCenter.default.currentInstanceAs(ShopApp.self)?.indicateProductItem(for: charge.payment, indicating:true)
            }

            productIdentifierFromAppStoreForTransaction = product.productIdentifier
            return true
        }

        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            
            //Pre-process with StoreKit
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                    case .purchased, .restored:
                        let downloads = purchase.transaction.downloads
                        if !downloads.isEmpty {
                            SwiftyStoreKit.start(downloads)
                        } else if purchase.needsFinishTransaction {
                            // Deliver content from server, then:
                            SwiftyStoreKit.finishTransaction(purchase.transaction)
                        }
                        print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")

                    case .failed, .purchasing, .deferred:
                        print("[!] WARNING: \(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                        break // do nothing
                }
            }
            
            //If user completes from App Store
            if let idByAppStore = productIdentifierFromAppStoreForTransaction, let c = AppCenter.charge.getChargesHasStorePayable()[idByAppStore]{

                for purchase in purchases where idByAppStore==purchase.productId{
                    let state = purchase.transaction.transactionState
                    guard state == .purchased || state == .restored else{
                        continue
                    }

                    // Pay with ChargeBank
                    if !AppCenter.charge.isPaid(payable: c.payment){
                        AppCenter.charge.pay(for: c.payment, skipTransaction: true)
                    }

                    // Reload Shop Products
                    DispatchQueue.main.async{
                        AppCenter.default.currentInstanceAs(ShopApp.self)?.reloadProductItems()

                        //Show alert for localCharge
                        if let cApp = _getLocalChargeableAppBy(storeProductIdentifier:purchase.productId) {
                            UIAlertController.alert("\n\("Would you like to go back to %@?".localizedFormatted(cApp.info.displayName))\n", title: "Thank you for your purchase.".localized, cancelButtonTitle: "Cancel".localized){ _ in
                                AppCenter.default.openApp(identifier: cApp.info.identifier)
                            }
                        }
                    }
                    break
                }


                //Dispose first
                productIdentifierFromAppStoreForTransaction = nil
                DispatchQueue.main.async{
                    AppCenter.default.currentInstanceAs(ShopApp.self)?.indicateProductItem(for: c.payment, indicating:false)
                }
            }

        }

        SwiftyStoreKit.updatedDownloadsHandler = { downloads in

            // contentURL is not nil if downloadState == .finished
            let contentURLs = downloads.compactMap {
                $0.contentURL
            }
            if contentURLs.count == downloads.count {
                print("Saving: \(contentURLs)")
                SwiftyStoreKit.finishTransaction(downloads[0].transaction)
            }
        }
    }

    //INFO: RestoredProductId will be filled only after calling restore()
    static private(set) var restoredProductIDs: Set<String>?

    //INFO: return Product IDs
    static func restore(_ signal: AsyncWaitSignalable) -> Set<String>? {
        var purchases: [Purchase]?

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

        guard let ids = purchases?.map({ $0.productId }) else {
            return nil
        }

        restoredProductIDs = Set(ids)
        return restoredProductIDs
    }


    //INFO: nil is Error
    typealias StoreProductFetchResult = (products:Set<SKProduct>, invalidProductIDs:Set<String>)

    //INFO: dont' directly access this without storeProductsFetchQueue
    fileprivate static var fetchedStoreProducts = [String:SKProduct]()

    @discardableResult
    static func fetch(for payables:[StorePayable.Type], _ signal: AsyncWaitSignalable) -> StoreProductFetchResult?{
        var resultProductInfo:StoreProductFetchResult?

        let requestedPayablesProductIdSet = Set(payables.map{ $0.product.identifier })

        //INFO: set already fetched info
        let fetchedPayables = payables.filter { $0.storeProduct != nil }
        var fetchedProductsSet = Set(fetchedPayables.compactMap{ $0.storeProduct })

        let unfetchedPayables = payables.filter { $0.storeProduct == nil }

        //not required fetch, return.
        if unfetchedPayables.count == 0{
            resultProductInfo = (products: fetchedProductsSet, invalidProductIDs: Set<String>())

        }else{
            let unfetchedPayablesProductIdSet = Set(unfetchedPayables.map { $0.product.identifier  })

            signal.begin()
            SwiftyStoreKit.retrieveProductsInfo(unfetchedPayablesProductIdSet) { (v: RetrieveResults) in
                if let err = v.error{
                    print("[!] ERROR \(#function): \(err.localizedDescription)")

                }else{
                    fetchedProductsSet = fetchedProductsSet.union(v.retrievedProducts)

                    resultProductInfo = (products: fetchedProductsSet, invalidProductIDs: v.invalidProductIDs)

                    for p in fetchedProductsSet {
                        if requestedPayablesProductIdSet.contains(p.productIdentifier){
                            StoreKitPayableCenter.fetchedStoreProducts[p.productIdentifier] = p
                        }else{
                            assert(false, "[!] WARNING: A product id: \(p.productIdentifier), localizedDescription: \(p.localizedDescription) is not registerd or unmatched.")
                        }
                    }

                }
                signal.end()
            }
            signal.waitUntilEnd()
        }

#if DEBUG
        if let resultProductInfo = resultProductInfo {
            //Validation
            if resultProductInfo.invalidProductIDs.count > 0{
                print("[!] WARNING: Following product ids: \(String(describing: resultProductInfo.invalidProductIDs)) is invalid products.")
            }

            let remainigProductIDs = requestedPayablesProductIdSet.subtracting(Set(resultProductInfo.products.map({ $0.productIdentifier })))
            if remainigProductIDs.count > 0{
                print("[!] WARNING: Following product ids: \(remainigProductIDs) was not fetched with In Store productIdentifers.")
            }
        }
#endif
        return resultProductInfo
    }
}

/*
    StoreKit Product Common Procedures
*/
private extension StoreProduct {
    func purchase(_ signal: AsyncWaitSignalable) -> Bool {
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
            }
            signal.end()
        }

        signal.waitUntilEnd()
        return paid
    }

    func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {
        let appleValidator = AppleReceiptValidator(service: papVerificationType, sharedSecret: papReceiptSecretKey)
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
                print("[!] WARNING: verifyReceipt error:", result)
                r = nil
            }
            signal.end()
        }
        signal.waitUntilEnd()
        return r
    }
}

extension StorePayable{
    static var storeProduct: SKProduct? {
        let storeProduct = StoreKitPayableCenter.fetchedStoreProducts[product.identifier]
#if DEBUG
        if #available(iOS 11.2, *) {
            if let storeSubscriptionPeriod = storeProduct?.subscriptionPeriod, storeSubscriptionPeriod.numberOfUnits > 0{
                assert(product.subscriptionPeriod != nil,"storeSubscriptionPeriod is existed, but local period not defined.")
                if let localSubscriptionPeriod = product.subscriptionPeriod{
                    assert(Int(localSubscriptionPeriod.numberOfUnits)==storeSubscriptionPeriod.numberOfUnits,"Not matched between Store Subscription Period Number.")
                    assert(localSubscriptionPeriod.unit.rawValue==storeSubscriptionPeriod.unit.rawValue+Period.Unit.day.rawValue,"Not matched between Store Subscription Period Unit.")
                }
            }
        }
#endif
        return storeProduct
    }

    @discardableResult
    static func fetchStoreProduct(_ signal: AsyncWaitSignalable) -> Bool {
        if storeProduct != nil{
            return true
        }

        if let fetchedInfo = StoreKitPayableCenter.fetch(for: [self], signal){
            for p in fetchedInfo.products where product.identifier == p.productIdentifier{
                return true
            }
        }
        return false
    }
}


/*
    Payment & Verification
*/
extension StorePayable{

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        if let _ = type(of: self).product.legalInfo{
            return _payWithLegalInfo(signal)

        }else{
            return _pay(signal)
        }
    }

    private func _payWithLegalInfo(_ signal: AsyncWaitSignalable) -> Bool{
        //INFO: fetch if needed.
        var fetched = false
        fetched = type(of: self).fetchStoreProduct(signal)
        assert(fetched)

        var proceeding = false
        signal.begin()
        DispatchQueue.main.async{
            self.presentLegalInfo(payable:self) { succeed in
                proceeding = succeed
                signal.end()
            }
        }
        signal.waitUntilEnd()

        let paid = proceeding ? _pay(signal) : false

        signal.begin()
        DispatchQueue.main.async{
            self.dismissLegalInfo()
            signal.end()
        }
        signal.waitUntilEnd()

        return paid
    }

    fileprivate func _pay(_ signal: AsyncWaitSignalable) -> Bool{
        return type(of: self).product.purchase(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        assert(false, "Use specific Payable Type.")
        return nil
    }
}

protocol NonConsumablePurchasingPayable:StorePayable{}
extension NonConsumablePurchasingPayable{
    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        return _verify(signal)
    }

    private func _verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).product.verify(signal) {

            let p = SwiftyStoreKit.verifyPurchase(
                    productId: r.product.identifier,
                    inReceipt: r.receipt)

            switch p {
                case .purchased( _):
                    return true
                default:
                    return false
            }
        }
        return nil
    }
}

protocol AutoRenewableSubscribingPayable:StorePayable{}
extension AutoRenewableSubscribingPayable {
    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        return _verify(signal)
    }

    private func _verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).product.verify(signal){

            switch SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: r.product.identifier,
                    inReceipt: r.receipt){

            case .purchased( _, _):
                return true

            default:
                return false
            }
        }
        return nil
    }
}

protocol NonRenewingSubscribingPayable:StorePayable{}
extension NonRenewingSubscribingPayable {
    fileprivate func _verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).product.verify(signal){
            switch SwiftyStoreKit.verifySubscription(
                    ofType: .nonRenewing(validDuration: papNonRenewingValidDuration),
                    productId: r.product.identifier,
                    inReceipt: r.receipt){

            case .purchased( _, _):
                return true
            default:
                return false
            }
        }
        return nil
    }
}


/*
    TrialablePayable & StorePayable
*/
extension StorePayable where Self:TrialablePayable{
    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).trial(or:{
            return self._pay(signal)
        })
    }
}
extension NonConsumablePurchasingPayable where Self:TrialablePayable{
    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        return type(of: self).verifyTrial() ?? _verify(signal)
    }
}
extension AutoRenewableSubscribingPayable where Self:TrialablePayable{
    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        return type(of: self).verifyTrial() ?? _verify(signal)
    }
}
extension NonRenewingSubscribingPayable where Self:TrialablePayable{
    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        return type(of: self).verifyTrial() ?? _verify(signal)
    }
}
