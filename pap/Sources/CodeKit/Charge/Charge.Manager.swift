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
        self.bank = ChargeBank(banker: banker)

        //validation
        var initCharges = [Charge]()
        let bankMaxValue = type(of: self.bank.balance).maxValue
        var sumOfPriceAmount = 0.0
        for c in charges{
            sumOfPriceAmount += c.priceAmount.value
            if sumOfPriceAmount > bankMaxValue{
                assert(false, "Sum of priceAmount must be same or lower than maxValue of given Bank \(bankMaxValue). It overflowed with \(sumOfPriceAmount-bankMaxValue).")
                break
            }
            initCharges.append(c)
        }

        self.charges = initCharges
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
}

/*
Private Interfaces
*/
final class ChargeBank: NSObject, KeyPathWatchable {
    private var defaults: ChargeDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: ChargeBank.self)+"UserDefaults") ?? UserDefaults.standard)

    @discardableResult
    private func synchronizeBalanceValue() -> Double{
        let finalValue = mutableBalance.set(banker.willSynchronizeBalanceValue(balance: mutableBalance)).value
        if defaults.balanceValue != finalValue{
            //commit
            defaults.balanceValue = finalValue
        }
        return finalValue
    }

    private let mutableBalance:MutableAmountObject

    fileprivate var balance:Amount{
        synchronizeBalanceValue()
        return mutableBalance
    }

    @objc dynamic
    private(set) var balanceValue:Double{
        set{} //only for broadcasting
        get{ return balance.value }
    }

    private let banker: ChargeBanker

    required init(banker: ChargeBanker.Type){
        self.banker = banker.init()

        let amount = MutableAmountObject(value:defaults.balanceValue)
        amount.set(self.banker.willInitialize(balance: amount))
        self.mutableBalance = amount
    }

    func deposit(for charge:Charge){
        if let priceAmount = banker.willSaveDeposit(forPriceAmountOf: charge, balance: mutableBalance){
            mutableBalance.add(priceAmount)
            balanceValue = synchronizeBalanceValue()
        }
        banker.didSaveDeposit(for: charge, balance: mutableBalance)
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

