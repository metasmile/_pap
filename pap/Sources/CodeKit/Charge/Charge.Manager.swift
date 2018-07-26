//
// Created by BLACKGENE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

class ChargeManager{

    private let payingQueue:DispatchQueue = DispatchQueue(label: String(describing: ChargeManager.self))

    let charges:[Charge]

    private(set) var bank: ChargeBank

    init(charges:[Charge], banker: ChargeBanker.Type){
        self.bank = ChargeBank(banker: banker)

//        //validation
//        var initCharges = [Charge]()
//        let bankMaxValue = type(of: self.bank.balance).maxValue
//        var sumOfPriceAmount = 0.0
//        for c in charges{
//            sumOfPriceAmount += c.priceAmount.value
//            if sumOfPriceAmount > bankMaxValue{
//                assert(false, "Sum of priceAmount must be same or lower than maxValue of given Bank \(bankMaxValue). It overflowed with \(sumOfPriceAmount-bankMaxValue).")
//                break
//            }
//            initCharges.append(c)
//        }
//        self.charges = initCharges

        self.charges = charges
    }

    func getCharge(for chargeable: Chargeable) -> Charge?{
        return charges.first { item in
            return (item as Chargeable).isEqual(other: chargeable)
        }
    }

    func getRemainingCharges(cheapFirst:Bool=false) -> [Charge]{
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

    /*
        Payment
    */
    func pay(for payable: Payable.Type, _ asyncSignal:AsyncWaitSignalable=AsyncSignal()){
        if let chargeToDeposit = getCharge(for: payable.charge) {
            payingQueue.async{
                if payable.init().pay(asyncSignal){

                    DispatchQueue.main.async{
                        self.bank.save(for:chargeToDeposit)
                    }
                }else{
                    print("[i] INFO: payment failed \(String(describing: payable))")
                }
            }
        }
    }

    func getPaidReceipt(for payable: Payable.Type) -> ChargeableReceipt?{
        return self.bank.getStoredReceipt(for: payable.charge)
    }
}