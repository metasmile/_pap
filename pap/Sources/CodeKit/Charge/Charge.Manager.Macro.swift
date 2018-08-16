//
// Created by BLACKGENE on 8/15/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ChargeManager{
    func getChargesPaidOwned(excluding types:Set<ChargeType>?=nil, synchronize:Bool=false) -> [Charge]{
        return getChargesPaid(excluding: types).filter { $0.reward.isOwned }
    }

    func getChargesHasReceipt(excluding types:Set<ChargeType>?=nil) -> [Charge]{
        return getCharges(excluding: types).filter { bank.getReceipt(for: $0) != nil }
    }

    func getChargesHasNotReceipt(excluding types:Set<ChargeType>?=nil) -> [Charge]{
        return getCharges(excluding: types).filter { bank.getReceipt(for: $0) == nil }
    }

    func getChargesPaidByStorePayable(excluding types:Set<ChargeType>?=nil) -> [Charge]{
        return getChargesPaid(excluding:types).filter({ $0.payment is StorePayable })
    }

    func getStorePayablesPaid(excluding types:Set<ChargeType>?=nil) -> [StorePayable.Type]{
        return getChargesPaidByStorePayable(excluding:types).compactMap({ $0.payment as? StorePayable.Type })
    }

    func getChargesHasStorePayable(excluding types:Set<ChargeType>?=nil) -> [String:Charge]{
        var storePayableCharges = [String:Charge]()
        for charge in self.getCharges(excluding: types){
            if let storePayableProductId = (charge.payment as? StorePayable.Type)?.product.identifier{
                storePayableCharges[storePayableProductId] = charge
            }
        }
        return storePayableCharges
    }

    func getChargesHasPricingInBalance(cheapFirst:Bool=false) -> [Charge]{
        if self.bank.balanceValue == 1{
            return []
        }

        let cheapFirstItems = self.getCharges().sorted { (item: Charge, item2: Charge) -> Bool in
            return item.priceAmount.value < item2.priceAmount.value
        }
        var remainingCharges = [Charge]()
        var sumOfValues = self.bank.balanceValue
        for item in cheapFirstItems {
            sumOfValues += item.priceAmount.value
            if sumOfValues > 1{
                break
            }
            remainingCharges.append(item)
        }
        return cheapFirst ? remainingCharges : remainingCharges.reversed()
    }
}
