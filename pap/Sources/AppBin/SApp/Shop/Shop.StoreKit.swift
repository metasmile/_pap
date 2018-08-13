//
// Created by BLACKGENE on 8/12/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
//INFO: SwiftyStoreKit's dependency is ONLY LOCATED in this file.
import SwiftyStoreKit

//INFO: pap specific Aug 10, 2018
private let papReceiptSecretKey = "791f81382c464b78803b22eba4fb2cde"
private let papNonRenewingValidDuration:TimeInterval = 60
#if DEBUG
private let papVerificationType = AppleReceiptValidator.VerifyReceiptURLType.sandbox
#else
private let papVerificationType = AppleReceiptValidator.VerifyReceiptURLType.production
#endif

struct StorePayableCenter {
    static func configure(){

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
            let contentURLs = downloads.compactMap { $0.contentURL }
            if contentURLs.count == downloads.count {
                print("Saving: \(contentURLs)")
                SwiftyStoreKit.finishTransaction(downloads[0].transaction)
            }
        }
    }

    //INFO: RestoredProductId will be filled only after calling restore()
    static private(set) var restoredProductIDs:Set<String>?

    static func restore(_ signal: AsyncWaitSignalable) -> Set<String>?{
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

        guard let ids = purchases?.map ({ $0.productId }) else {
            return nil
        }

        restoredProductIDs = Set(ids)
        return restoredProductIDs
    }
}

extension StorePayable{
    static var payingLabel:String {
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
    static var payingLabel: String{
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
    static var payingLabel: String{
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
                signal.end()
            }
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