//
// Created by BLACKGENE on 8/12/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
//INFO: SwiftyStoreKit's dependency is ONLY LOCATED in this file.
import SwiftyStoreKit
import StoreKit

//INFO: pap specific Aug 10, 2018
private let papReceiptSecretKey = "791f81382c464b78803b22eba4fb2cde"
private let papNonRenewingValidDuration:TimeInterval = 60
#if DEBUG
private let papVerificationType = AppleReceiptValidator.VerifyReceiptURLType.sandbox
#else
private let papVerificationType = AppleReceiptValidator.VerifyReceiptURLType.production
#endif


//INFO: StorePayableCenter: Not recommended to use in Charge-ChargeBank-ChargeBanker family directly.
// Use in only in an ShopApp. When add Directory-Scoped access permission in swift?? huh.
struct StorePayableCenter {
    static func configure() {

        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
/**/
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
    typealias StorePayableProductInfo = (products:Set<SKProduct>, invalidProductIDs:Set<String>)

    static func retrieve(for eachPayables:[StorePayable.Type], _ signal: AsyncWaitSignalable) -> StorePayableProductInfo?{
        var productInfos:StorePayableProductInfo?

        signal.begin()

        SwiftyStoreKit.retrieveProductsInfo(Set(eachPayables.map { $0.product.identifier  })) { (v: RetrieveResults) in
            if let err = v.error{
                print("[!] ERROR \(#function): \(err.localizedDescription)")

            }else{
                productInfos = (products: v.retrievedProducts, invalidProductIDs:v.invalidProductIDs)
            }
            signal.end()
        }
        signal.waitUntilEnd()

        return productInfos
    }

}

private extension StorePayableProduct {
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

    func verify(_ signal: AsyncWaitSignalable) -> (product: StorePayableProduct, receipt:ReceiptInfo)? {
        var r:(product: StorePayableProduct, receipt:ReceiptInfo)?

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
    static var label:String {
        return "Purchase".localized
    }

    func pay(_ signal: AsyncWaitSignalable) -> Bool {
        return type(of: self).product.purchase(signal)
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        assert(false, "Use specific Payable Type.")
        return false
    }
}


protocol NonConsumablePurchasingPayable:StorePayable{}
extension NonConsumablePurchasingPayable{
    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
        if let r = type(of: self).product.verify(signal) {

            switch SwiftyStoreKit.verifyPurchase(
                    productId: r.product.identifier,
                    inReceipt: r.receipt) {

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
    static var label: String{
        return "Subscribe".localized
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
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
    static var label: String{
        return "Subscribe".localized
    }

    func verify(_ signal: AsyncWaitSignalable) -> Bool? {
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
