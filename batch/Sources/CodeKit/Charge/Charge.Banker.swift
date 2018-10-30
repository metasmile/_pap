//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

protocol ChargeBanker {
    static var version:Int{get}

    //INFO: WARNING: If receiptStorageIdentifier changed, existed receipt information will be destroyed.
    var receiptStorageIdentifier:String{get}
    func getReceipt(for chargeable:Chargeable) -> ChargeableReceipt?

    //INFO: init balance.
    func initializeBank() -> Amount

    func willInitializeBank(balance:Amount)
    func didInitializeBank(verifiedResults:ChargeableReceiptVerificationResult, balance:Amount)

    //INFO: return ChargeBank. balanceValue - this method may call significantly.
    // handle carefully for maintaining high performance.
    func synchronize(balance:Amount) -> Amount

    //INFO: return charged price amount or nil.
    func willSaveDeposit(forPriceAmountOf charge:Charge, balance:Amount) -> Amount?
    func didSaveDeposit(for charge:Charge, balance:Amount)

    func didDeclineDeposit(for charge:Charge)

    init(registeredCharges:[Charge])
}
