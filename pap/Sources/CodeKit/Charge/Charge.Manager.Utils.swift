//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ChargeManager{
    func getChargesHasPricingInBalance(cheapFirst:Bool=false) -> [Charge]{
        if self.bank.balanceValue == 1{
            return []
        }

        let cheapFirstItems = charges.sorted { (item: Charge, item2: Charge) -> Bool in
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

    func getChargesHasReceipt() -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            return bank.getReceipt(for: charge) != nil
        }
    }

    func getChargesHasNotReceipt() -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            return bank.getReceipt(for: charge) == nil
        }
    }

    func getChargesHasNotReceiptButHasPriceAmount() -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            return bank.getReceipt(for: charge) == nil && charge.priceAmount.value > 0
        }
    }
}