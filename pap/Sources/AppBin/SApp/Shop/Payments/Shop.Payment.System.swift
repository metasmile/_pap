//
// Created by BLACKGENE on 8/16/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

struct FreeAppPayment<T:App>: VerifiablePayable{
    static var action: PayableAction {
        return PayableAction(title: "Free Use".localized)
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return true
    }
    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return true
    }
}

struct RestorePurchasesSystemPayment:VerifiablePayable{
    static var action: PayableAction {
        return PayableAction(title: "Restore".localized)
    }

    static var isEnable: Bool {
        let inVipMode = AppCenter.charge.getChargesPaid().contains { charge in
            charge.payment.identifier == SecretCodeProgramPayment<PermanentVIPSecretCodeProgram>.identifier
        }
        return inVipMode == false && AppCenter.charge.getChargesPaidByStorePayable().count == 0
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        let chargesByProductID = AppCenter.charge.getChargesHasStorePayable()
        let productIDs = Set(chargesByProductID.keys)
        let paidProductIDs = Set(AppCenter.charge.getStorePayablesPaid().map { $0.product.identifier })
        let unpaidProductIDs = productIDs.subtracting(paidProductIDs)

        if let restoredProductIds = StoreKitPayableCenter.restore(asyncSignal), restoredProductIds.count > 0{

            let restoredDeprecatedIDs = restoredProductIds.subtracting(productIDs)
            let restoredLiveIDs = restoredProductIds.subtracting(restoredDeprecatedIDs)
            let restoredUnpaidIDs = restoredLiveIDs.intersection(unpaidProductIDs)

            print("[!] WARNING: Found deprecated restored IDs: \(restoredDeprecatedIDs)")
            assert(restoredLiveIDs.subtracting(productIDs).count == 0, "restoredLiveIDs must contain all in productIDs")

#if DEBUG
            // IDs does not only contain in restoredProductIds but also unpaid. Invalid case.
            var unRestoredAndUnpaidIDs = Set<String>()
            for unRestoredId in Set(chargesByProductID.keys).subtracting(restoredLiveIDs){
                if let charge = chargesByProductID[unRestoredId], AppCenter.charge.isPaid(charge: charge) == false{
                    unRestoredAndUnpaidIDs.insert(unRestoredId)
                }
            }
            print("[i] Found unrestored, but also unpaid products: \(unRestoredAndUnpaidIDs)")

#endif

            var paidCount = 0
            for productId in restoredUnpaidIDs {
                if let storePayableCharge = chargesByProductID[productId]{
                    AppCenter.charge.pay(for: storePayableCharge.payment, skipTransaction:true)
                    paidCount += 1
                }else{
                    assert(false, "[!] ERROR: product ID: \(productId) is not in chargesByProductID: \(chargesByProductID)")
                }
            }

            assert(paidCount==restoredUnpaidIDs.count, "[!] ERROR: Some payment of restored but unpaidIDs are failed.")
            return restoredUnpaidIDs.count==paidCount
        }

        return false
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return AppCenter.charge.getChargesPaidByStorePayable().count > 0
    }
}
