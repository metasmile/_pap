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
        let charge = charges.first { item in
            return (item as Chargeable).isEqual(other: chargeable)
        }
        assert(charge != nil, "\(String(describing: chargeable)) is not registered in ChargeableManager. Please register with initializer.")
        return charge
    }

    /*
        Payment
    */
    func pay(for payable: Payable.Type, _ asyncSignal:AsyncWaitSignalable=AsyncSignal()){
        guard let charge = getCharge(for: payable.charge) else {
            return
        }

        payingQueue.async{
            if payable.init().pay(asyncSignal){

                DispatchQueue.main.async{
                    self.bank.save(for: charge)
                }
            }else{
                print("[i] INFO: payment failed \(String(describing: payable))")
            }
        }
    }
}