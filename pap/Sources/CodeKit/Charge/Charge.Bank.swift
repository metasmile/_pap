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
    func didInitializeBank(balance:Amount)

    //INFO: return ChargeBank. balanceValue - this method may call significantly.
    // handle carefully for maintaining high performance.
    func synchronizeBalanceValue(balance:Amount) -> Amount

    //INFO: return charged price amount or nil.
    func willSaveDeposit(forPriceAmountOf charge:Charge, balance:Amount) -> Amount?
    func didSaveDeposit(for charge:Charge, balance:Amount)

    func didDeclineDeposit(for charge:Charge)

    init(registeredCharges:[Charge])
}

extension ChargeBank{
    func getReceipt(for charge:Chargeable) -> ChargeableReceipt?{
        return self.banker.getReceipt(for: charge)
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

    func save(for charge:Charge){
        if let _ = banker.willSaveDeposit(forPriceAmountOf: charge, balance: synchronizedBalance){
            synchronizeBalanceValue()
            balanceValue = synchronizedBalance.value
            banker.didSaveDeposit(for: charge, balance: synchronizedBalance)
        }
    }

    func cancelToSave(for charge:Charge){
        banker.didDeclineDeposit(for: charge)
    }
}
