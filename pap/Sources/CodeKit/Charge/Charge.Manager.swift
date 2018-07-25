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

    private lazy var balance = ChargeManagerBalanceAmount(value: defaults.balanceAmountsValue, manager:self)

    init(charges:[Charge]){
        self.charges = charges
    }

    func resetBalance(){
#if DEBUG
        print("[i]INFO: In the release build, balance resetting will not be performed.")
        balance = ChargeManagerBalanceAmount(value: 0, manager:self)
#endif
    }

    func getCharge(for payable: Payable.Type) -> Charge?{
        return charges.first { item in
            return (item as Chargeable).isEqual(other: payable.charge)
        }
    }

    func getRemainingCharges(cheapFirst:Bool=false) -> [Charge]{
        if self.balance.value == 1{
            return []
        }

        let cheapFirstItems = charges.sorted { (item: Charge, item2: Charge) -> Bool in
            return item.priceAmount.value < item2.priceAmount.value
        }
        var remainingCharges = [Charge]()
        var bal = self.balance.value
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
        if let chargeToDeposit = getCharge(for: payable) {
            payingQueue.async{
                if payable.init().pay(asyncSignal){

                    DispatchQueue.main.async{
                        self.balance.deposit(for:chargeToDeposit)
                    }
                }else{
                    print("[i] INFO: payment failed \(String(describing: payable))")
                }
            }
        }
    }

    func isPaid(for payable:Payable.Type) -> Bool{
        //TODO: consumption unit date, app use count etc.
        return self.balance.value > getCharge(for: payable)?.priceAmount.value ?? 0
    }
}

/*
    Basic Implementation.
*/

extension AmountObject{
    static let minValue:Double = 0
    static let maxValue:Double = 1
}

class AmountObject:Amount{
    @objc dynamic
    fileprivate(set) var value: Double = Double.nan

    required init(value: Double) {
        if value >= type(of: self).minValue && value <= type(of: self).maxValue {
            self.value = value
        }else{
            assert(false,"Amount is allowed only 0...1")
        }
    }
}

class MutableAmountObject: AmountObject, MutableAmount{
    @discardableResult
    func add(_ amount: Amount) -> Amount {
        self.value += clamp(amount.value, type(of: self).minValue, type(of: self).maxValue - value)
        return self
    }

    @discardableResult
    func subtract(_ amount: Amount) -> Amount {
        self.value -= clamp(amount.value, type(of: self).minValue, value)
        return self
    }
}

/*
Private Interfaces
*/
private class ChargeManagerBalanceAmount: MutableAmountObject{
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

    func deposit(for charge:Charge){
        //TODO: register consumption actions by reward type, only when charge.priceAmount == MutableAmount
        // charge.reward
        self.add(charge.priceAmount)
    }

    private func consume(for charge:Charge){
        self.subtract(charge.priceAmount)
    }

    @discardableResult
    override func add(_ amount: Amount) -> Amount {
        return super.add(amount)
    }

    @discardableResult
    override func subtract(_ amount: Amount) -> Amount {
        return super.subtract(amount)
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

