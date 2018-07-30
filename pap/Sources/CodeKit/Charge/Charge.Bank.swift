//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol ChargeBanker {
    static var version:Int{get}

    //INFO: WARNING: If receiptStorageIdentifier changed, existed receipt information will be destroyed.
    var receiptStorageIdentifier:String{get}
    func getReceipt(for chargeable:Chargeable) -> ChargeableReceipt?

    //INFO: init balance.
    func initializeBank() -> Amount
    func didInitializeBank(balance:MutableAmount)

    //INFO: return ChargeBank. balanceValue - this method may call significantly.
    // handle carefully for maintaining high performance.
    func willSynchronizeBalanceValue(balance:MutableAmount) -> Amount

    //INFO: return charged price amount or nil.
    func willSaveDeposit(forPriceAmountOf charge:Charge, balance:MutableAmount) -> Amount?
    func didSaveDeposit(for charge:Charge, balance:MutableAmount)

    init(registeredCharges:[Charge])
}

extension ChargeBank{
    func getReceipt(for charge:Chargeable) -> ChargeableReceipt?{
        return self.banker.getReceipt(for: charge)
    }
}

final class ChargeBank: NSObject, KeyPathWatchable {
    @discardableResult
    private func synchronizeBalanceValue() -> Double{
        return mutableBalance.set(banker.willSynchronizeBalanceValue(balance: mutableBalance)).value
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

        let amount = MutableAmountObject(value:0)
        amount.set(self.banker.initializeBank())
        self.mutableBalance = amount
        self.banker.didInitializeBank(balance: self.mutableBalance)
    }

    func save(for charge:Charge){
        if let priceAmount = banker.willSaveDeposit(forPriceAmountOf: charge, balance: mutableBalance){
            mutableBalance.add(priceAmount)
            balanceValue = synchronizeBalanceValue()
        }
        banker.didSaveDeposit(for: charge, balance: mutableBalance)
    }
}
