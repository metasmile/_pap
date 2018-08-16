//
// Created by BLACKGENE on 8/16/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

struct RestorePurchasesSystemPayment:VerifiablePayable{
    static var label: String {
        return "Restore".localized
    }

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {

        let productIdByCharges = AppCenter.charge.getChargesByStorePayableProductIdentifier()

        if let restoredProductIds = StorePayableCenter.restore(asyncSignal){
            for productId in restoredProductIds {
                if let storePayableCharge = productIdByCharges[productId]{
                    AppCenter.charge.pay(for: storePayableCharge.payment, skipTransaction:true)
                }
            }
            return true
        }

        return false
    }

    func verify(_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return nil
    }
}