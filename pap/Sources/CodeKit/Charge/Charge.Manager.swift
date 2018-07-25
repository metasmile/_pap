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

    init(charges:[Charge], banker: ChargeBanker.Type){
        self.charges = charges
        self.bank = ChargeBank(banker: banker)
    }

    func resetBalance(){
#if DEBUG
        print("[i]INFO: In the release build, balance resetting will not be performed.")
        bank.balanceValue = 0
#endif
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
        var bal = self.bank.balanceValue
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
        if let chargeToDeposit = getCharge(for: payable.charge) {
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
        return self.bank.balanceValue > getCharge(for: payable.charge)?.priceAmount.value ?? 0
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
final class ChargeBank: NSObject, KeyPathWatchable {
    private var defaults: ChargeDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: ChargeBank.self)+"UserDefaults") ?? UserDefaults.standard)

    private let balanceAmount:MutableAmountObject

    @objc dynamic
    fileprivate(set) var balanceValue:Double{
        set{
            balanceAmount.value = newValue
            self.defaults.balanceValue = newValue
        }
        get{
            balanceAmount.value = banker.willGetBalanceValue(balance: balanceAmount).value
            return balanceAmount.value
        }
    }

    private let banker: ChargeBanker

    required init(banker: ChargeBanker.Type){
        self.banker = banker.init()

        self.balanceAmount = MutableAmountObject(value:defaults.balanceValue)
        self.balanceAmount.value = self.banker.willInitialize(balance: self.balanceAmount).value
    }

    func deposit(for charge:Charge){
        if let priceAmount = banker.willDeposit(priceAmountFor: charge, balance: balanceAmount){
            balanceValue = balanceAmount.add(priceAmount).value
        }
        banker.didDeposit(for: charge, balance: balanceAmount)
    }

    fileprivate func consume(for charge:Charge){
        balanceValue = balanceAmount.subtract(charge.priceAmount).value
    }
}

private protocol ChargeDefaults:DefaultsProperty{
    var balanceValue: Double {set get}
}

extension Defaults: ChargeDefaults {
    fileprivate var balanceValue: Double {
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

