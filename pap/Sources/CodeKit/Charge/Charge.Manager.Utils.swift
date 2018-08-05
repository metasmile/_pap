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

    func getChargesHasPriceAmount(excludingTypes:Set<ChargeType>?=nil) -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            if let excludingTypes = excludingTypes, excludingTypes.contains(charge.type){
                return false
            }
            return charge.priceAmount.value > 0
        }
    }

    func getChargesHasReceipt(excludingTypes:Set<ChargeType>?=nil) -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            if let excludingTypes = excludingTypes, excludingTypes.contains(charge.type){
                return false
            }
            return bank.getReceipt(for: charge) != nil
        }
    }

    func getChargesHasReceiptAlsoHasPriceAmount(excludingTypes:Set<ChargeType>?=nil) -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            if let excludingTypes = excludingTypes, excludingTypes.contains(charge.type){
                return false
            }
            return bank.getReceipt(for: charge) != nil && charge.priceAmount.value > 0
        }
    }

    func hasOneChargeHasReceiptAlsoHasPriceAmountAtLeast(excludingTypes:Set<ChargeType>?=nil) -> Bool{
        let c = getChargesHasPriceAmount(excludingTypes: excludingTypes).first { charge in
            return bank.getReceipt(for: charge) != nil
        }
        return c != nil
    }

    func areAllChargesHasPriceAmountPaid(excludingTypes:Set<ChargeType>?=nil) -> Bool{
        let cl = getChargesHasPriceAmount(excludingTypes: excludingTypes)
        return cl.filter { (charge: Charge) -> Bool in
            return bank.getReceipt(for: charge) != nil
        }.count == cl.count
    }

    func getChargesHasNotReceipt(excludingTypes:Set<ChargeType>?=nil) -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            if let excludingTypes = excludingTypes, excludingTypes.contains(charge.type){
                return false
            }
            return bank.getReceipt(for: charge) == nil
        }
    }

    func getChargesHasNotReceiptButHasPriceAmount(excludingTypes:Set<ChargeType>?=nil) -> [Charge]{
        return charges.filter { (charge: Charge) -> Bool in
            if let excludingTypes = excludingTypes, excludingTypes.contains(charge.type){
                return false
            }
            return bank.getReceipt(for: charge) == nil && charge.priceAmount.value > 0
        }
    }
}