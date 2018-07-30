//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol ChargeReceiptStorable where Self:ChargeBanker{
    //INFO: WARNING: If storageIdentifier changed, existed receipt information will be destroyed.
    var storageIdentifier:String{get}

    func getReceipt(for chargeable:Chargeable) -> ChargeableReceipt?
}

extension ChargeBank{
    func getStoredReceipt(for charge:Chargeable) -> ChargeableReceipt?{
        return (self.banker as? ChargeReceiptStorable)?.getReceipt(for: charge)
    }
}

protocol ChargeBanker {
    static var version:Int{get}

    //INFO: setup something stuffs
    func willInitialize(balance:MutableAmount) -> Amount
    func didInitialize(balance:MutableAmount)

    //INFO: return ChargeBank. balanceValue - this method may call significantly.
    // handle carefully for maintaining high performance.
    func willSynchronizeBalanceValue(balance:MutableAmount) -> Amount

    //INFO: return charged price amount or nil.
    func willSaveDeposit(forPriceAmountOf charge:Charge, balance:MutableAmount) -> Amount?
    func didSaveDeposit(for charge:Charge, balance:MutableAmount)

    init(registeredCharges:[Charge])
}

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

    required init(banker: ChargeBanker.Type, registeredCharges:[Charge]){
        self.banker = banker.init(registeredCharges:registeredCharges)

        let amount = MutableAmountObject(value:defaults.balanceValue)
        amount.set(self.banker.willInitialize(balance: amount))
        self.mutableBalance = amount
        self.banker.didInitialize(balance: self.mutableBalance)
    }

    func save(for charge:Charge){
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

