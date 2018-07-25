//
// Created by BLACKGENE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

class ChargeManager: NSObject, KeyPathWatchable{

    private let payingQueue:DispatchQueue = DispatchQueue(label: String(describing: ChargeManager.self))
    fileprivate let defaults: ChargeDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: type(of: self))+"UserDefaults") ?? UserDefaults.standard)

    private let charges:[Charge] // type: price

    //INFO: Watchable + read-only. Don't set directly.
    @objc dynamic
    fileprivate (set) var balanceAmountsValue:Double = 0

    private lazy var balance = BalanceAmount(value: self.defaults.balanceAmountsValue, manager:self)

    init(charges:[Charge]){
        self.charges = charges
    }

    func resetBalance(){
#if DEBUG
        print("[i]INFO: In the release build, balance resetting will not be performed.")
        balanceAmountsValue = 0
#endif
    }

    func getCharge(for payable: Payable.Type) -> Charge?{
        return charges.first { item in
            return (item as Chargeable).isEqual(other: payable.charge)
        }
    }

    func getRemainingCharges(cheapFirst:Bool=false) -> [Charge]{
        if balanceAmountsValue == 1{
            return []
        }

        let cheapFirstItems = charges.sorted { (item: Charge, item2: Charge) -> Bool in
            return item.priceAmount.value < item2.priceAmount.value
        }
        var remainingCharges = [Charge]()
        var bal = self.balanceAmountsValue
        for item in cheapFirstItems {
            bal += item.priceAmount.value
            if bal > 1{
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
        if let priceAmount = getCharge(for: payable)?.priceAmount {
            let currentBalanceAmountValue = self.balanceAmountsValue
            payingQueue.async{
                if payable.init().pay(asyncSignal){

                    DispatchQueue.main.async{
                        self.balanceAmountsValue += clamp(priceAmount.value, 0, 1 - currentBalanceAmountValue)
                    }
                }else{
                    print("[i] INFO: payment failed \(String(describing: payable))")
                }
            }
        }
    }

    func isPaid(for payable:Payable.Type) -> Bool{
        //TODO: consumption unit date, app use count etc.
        return balanceAmountsValue > getCharge(for: payable)?.priceAmount.value ?? 0
    }
}

/*
    Basic Implementation.
*/
class AmountObject:Amount{
    fileprivate(set) var value: Double = Double.nan

    required init(value: Double) {
        if value>=0.0 && value<=1.0 {
            self.value = value
        }else{
            assert(false,"Amount is allowed only 0...1")
        }
    }
}

class MutableAmountObject: AmountObject, MutableAmount{
    @discardableResult
    func add(_ amount: Amount) -> Amount {
        self.value += amount.value
        return self
    }

    @discardableResult
    func subtract(_ amount: Amount) -> Amount {
        self.value -= amount.value
        return self
    }
}

/*
Private Interfaces
*/
private class BalanceAmount: MutableAmountObject{
    private var manager:ChargeManager?

    required init(value: Double) {
        super.init(value: value)
    }

    convenience init(value: Double, manager:ChargeManager?){
        self.init(value: value)
        self.manager = manager
    }

    override var value: Double {
        get {
            return super.value
        }
        set {
            super.value = newValue

            var defaults = self.manager?.defaults
            defaults?.balanceAmountsValue = newValue
            manager?.balanceAmountsValue = newValue
        }
    }
}

private protocol ChargeDefaults:DefaultsProperty{
    var balanceAmountsValue: Double {set get}
}

extension Defaults: ChargeDefaults {
    fileprivate var balanceAmountsValue: Double {
        set{
            if newValue>=0.0 && newValue<=1.0 {
                set(newValue)
            }else{
                assert(false,"charged balance is allowed only 0...1")
            }
        }
        get { return get(or:0) }
    }
}

