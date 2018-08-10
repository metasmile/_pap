//
// Created? by BLACKGENE on 24.07.18.
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
        //Validation
        var initializingCharges = [Charge]()
        var initializingChargeIdSet = Set<String>()
        for c in charges where initializingChargeIdSet.contains(c.identifier) == false{
            initializingChargeIdSet.insert(c.identifier)
            initializingCharges.append(c)
        }
        assert(charges.count == initializingCharges.count, "Duplicated charges have same identifiers. \(Set(charges.map{ $0.identifier }).symmetricDifference(Set(initializingCharges.map{ $0.identifier })))")

        self.charges = initializingCharges
        self.bank = ChargeBank(banker: banker, registeredCharges: self.charges)
    }

    func getCharge(for chargeable: Chargeable) -> Charge?{
        let charge = charges.first { item in
            return (item as Chargeable).isEqualTo(other: chargeable)
        }
        assert(charge != nil, "\(String(describing: chargeable)) is not registered in ChargeableManager. Please register with initializer.")
        return charge
    }

    func getCharge(for payable: Payable.Type) -> Charge?{
        let charge = charges.first { item in
            return item.payment == payable
        }
        assert(charge != nil, "\(String(describing: payable)) is not registered in ChargeableManager. Please register with initializer.")
        return charge
    }

    /*
        Payment
    */
    func pay(for payable: Payable.Type, _ asyncSignal:AsyncWaitSignalable=AsyncSignal(), completion:((_ succeed:Bool) -> ())?=nil){
        guard let charge = charges.first(where:{ $0.payment == payable }) else {
            return
        }

        payingQueue.async{
            if payable.init().pay(asyncSignal){
                DispatchQueue.main.async{
                    let result = self.bank.save(for: charge)
                    completion?(result)
                }
            }else{
                DispatchQueue.main.async{
                    self.bank.cancelToSave(for: charge)
                    completion?(false)
                }
                print("[i] INFO: payment failed \(String(describing: payable))")
            }
        }
    }
}

final class ChargeBank: NSObject, KeyPathWatchable {
    private var synchronizedBalance:Amount

    private func synchronizeBalanceValue() {
        synchronizedBalance = banker.synchronizeBalanceValue(balance: synchronizedBalance)
    }

    @objc dynamic
    private(set) var balanceValue:Double{
        set{ } //only for broadcasting
        get{
            synchronizeBalanceValue()
            return synchronizedBalance.value
        }
    }

    private let banker: ChargeBanker

    required init(banker: ChargeBanker.Type, registeredCharges:[Charge]){
        self.banker = banker.init(registeredCharges:registeredCharges)
        self.synchronizedBalance = self.banker.initializeBank()
        self.banker.didInitializeBank(balance: self.synchronizedBalance)
    }

    func getReceipt(for charge:Chargeable) -> ChargeableReceipt?{
        return self.banker.getReceipt(for: charge)
    }

    @discardableResult
    fileprivate func save(for charge:Charge) -> Bool{
        if let _ = banker.willSaveDeposit(forPriceAmountOf: charge, balance: synchronizedBalance){
            synchronizeBalanceValue()
            balanceValue = synchronizedBalance.value
            banker.didSaveDeposit(for: charge, balance: synchronizedBalance)
            return true
        }
        return false
    }

    fileprivate func cancelToSave(for charge:Charge){
        banker.didDeclineDeposit(for: charge)
    }
}
