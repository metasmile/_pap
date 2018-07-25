//
// Created by BLACKGENE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

class ChargeManager{

    private let payingQueue:DispatchQueue = DispatchQueue(label: String(describing: ChargeManager.self))

    private let charges:[Charge]

    private(set) var bank: ChargeBank

    init(charges:[Charge], bankDelegate:ChargeBankDelegate.Type){
        self.charges = charges
        self.bank = ChargeBank(delegate: bankDelegate)
    }

    func resetBalance(){
#if DEBUG
        print("[i]INFO: In the release build, balance resetting will not be performed.")
        bank.balanceAmountsValue = 0
#endif
    }

    func getCharge(for payable: Payable.Type) -> Charge?{
        return charges.first { item in
            return (item as Chargeable).isEqual(other: payable.charge)
        }
    }

    func getRemainingCharges(cheapFirst:Bool=false) -> [Charge]{
        if self.bank.balanceAmountsValue == 1{
            return []
        }

        let cheapFirstItems = charges.sorted { (item: Charge, item2: Charge) -> Bool in
            return item.priceAmount.value < item2.priceAmount.value
        }
        var remainingCharges = [Charge]()
        var bal = self.bank.balanceAmountsValue
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
                        self.bank.deposit(for:chargeToDeposit)
                    }
                }else{
                    print("[i] INFO: payment failed \(String(describing: payable))")
                }
            }
        }
    }

    func isPaid(for payable:Payable.Type) -> Bool{
        //TODO: consumption unit date, app use count etc.
        return self.bank.balanceAmountsValue > getCharge(for: payable)?.priceAmount.value ?? 0
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
protocol ChargeBankDelegate{
    func willInitialize(balance:MutableAmount) -> Amount
    func willDeposit(for charge:Charge, balance:MutableAmount) -> Amount?
    func didDeposit(for charge:Charge, balance:MutableAmount)

    init()
}

final class ChargeBank: NSObject, KeyPathWatchable {
    private lazy var defaults: ChargeDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: ChargeBank.self)+"UserDefaults") ?? UserDefaults.standard)

    private lazy var amount:MutableAmountObject = MutableAmountObject(value:defaults.balanceAmountsValue)

    @objc dynamic
    fileprivate (set) lazy var balanceAmountsValue:Double = self.delegate.willInitialize(balance: amount).value

    private var delegate:ChargeBankDelegate

    required init(delegate:ChargeBankDelegate.Type){
        self.delegate = delegate.init()
    }

    func deposit(for charge:Charge){
        if let priceAmount = delegate.willDeposit(for: charge, balance: amount){
            balanceAmountsValue = amount.add(priceAmount).value
            commitBalanceAmount()
        }
        delegate.didDeposit(for: charge, balance: amount)
    }

    fileprivate func consume(for charge:Charge){
        balanceAmountsValue = amount.subtract(charge.priceAmount).value
        commitBalanceAmount()
    }

    private func commitBalanceAmount(){
        defaults.balanceAmountsValue = self.balanceAmountsValue
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

