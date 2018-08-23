//
// Created? by BLACKGENE on 24.07.18.
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
        //Validation
        var initializingCharges = [Charge]()
        var validatingChargeIdSet = Set<String>()
        var validatingPaymentSet = Set<String>()
        for c in charges where validatingChargeIdSet.contains(c.identifier) == false{
            validatingChargeIdSet.insert(c.identifier)
            validatingPaymentSet.insert(String(describing: c.payment))
            initializingCharges.append(c)
        }
        assert(initializingCharges.count == validatingPaymentSet.count, "Duplicated charges have same payment type. \(Set(charges.map{ String(describing: $0.payment) }).symmetricDifference(Set(validatingPaymentSet.map{ $0 })))")
        assert(charges.count == initializingCharges.count, "Duplicated charges have same identifiers. \(Set(charges.map{ $0.identifier }).symmetricDifference(Set(initializingCharges.map{ $0.identifier })))")

        self.charges = initializingCharges
        self.bank = ChargeBank(banker: banker, registeredCharges: self.charges)

#if DEBUG
        let storePayables = getCharges().compactMap{ $0.payment as? StorePayable.Type }
        assert(storePayables.count == Set(storePayables.map({ $0.product.identifier })).count, "[!!] FATAL ERROR: Duplicated StorePayable product identifer found.")
#endif
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

    func getCharges(excluding types:Set<ChargeType>?=nil) -> [Charge]{
        return charges.filter { !(types?.contains($0.type) == true) }
    }

    func getChargesPaid(excluding types:Set<ChargeType>?=nil, synchronize:Bool=false) -> [Charge]{
        if synchronize{
            bank.synchronize()
        }
        return getCharges(excluding: types).filter { isPaid(charge: $0) }
    }

    func areAllChargesPaid(excluding types:Set<ChargeType>?=nil, synchronize:Bool=false) -> Bool{
        if synchronize{
            bank.synchronize()
        }
        return getCharges(excluding: types).count == getChargesPaid(excluding:types).count
    }

    func isPaid(charge chargeable:Chargeable, synchronize:Bool=false) -> Bool {
        return isPaid(payable:chargeable.payment)
    }

    func isPaid(payable:Payable.Type, synchronize:Bool=false) -> Bool{
        if synchronize{
            bank.synchronize()
        }

        if let charge = charges.first(where: { $0.payment == payable })
        , let receipt = bank.getReceipt(for: charge){
            return receipt.verify()
        }
        return false
    }

    func pay(for payable: Payable.Type, skipTransaction:Bool=false, completion:((_ succeed:Bool) -> ())?=nil){
        guard let charge = charges.first(where:{ $0.payment == payable }) else {
            assert(false, "All Payables must be registerd.")
            completion?(false)
            return
        }

        if isPaid(payable: payable){
            assert(false, "Payable \(String(describing: payable)) was already paid.")
            completion?(true)
            return
        }

        if skipTransaction{
            print("[i] INFO: Skipping Payment Transaction: \(String(describing: payable))")

            DispatchQueue.main.async{
                completion?(self.bank.save(for: charge))
            }
            return
        }

        self.try(for: payable) { succeed in
            if succeed{
                let result = self.bank.save(for: charge)
                completion?(result)
            }else{
                self.bank.cancelToSave(for: charge)
                completion?(false)
                print("[i] INFO: payment failed \(String(describing: payable))")
            }
        }
    }

    func `try`(for payable: Payable.Type, completion:((_ succeed:Bool) -> ())?=nil){
        payingQueue.async{
            let dispatchQueue = DispatchQueue.main

            if payable.init().pay(AsyncSignal()){
                dispatchQueue.async{
                    completion?(true)
                }
            }else{
                dispatchQueue.async{
                    completion?(false)
                }
            }
        }
    }
}

final class ChargeBank: NSObject, KeyPathWatchable {
    private var synchronizedBalance:Amount

    fileprivate func synchronize() {
        synchronizedBalance = banker.synchronize(balance: synchronizedBalance)
    }

    @objc dynamic
    private(set) var balanceValue:Double{
        set{ } //only for broadcasting
        get{
            synchronize()
            return synchronizedBalance.value
        }
    }

    private let banker: ChargeBanker
    private let registeredCharges:[Charge]

    required init(banker: ChargeBanker.Type, registeredCharges:[Charge]){
        self.registeredCharges = registeredCharges
        self.banker = banker.init(registeredCharges:registeredCharges)
        self.synchronizedBalance = self.banker.initializeBank()

        super.init()
        self.didInitializeBanker()
    }

    private func didInitializeBanker(){
        let balance = self.synchronizedBalance

        self.banker.willInitializeBank(balance: balance)

        DispatchQueue(label: UUID().uuidString).async{ //Non-accessible queue
            let signal = AsyncSignal()

            //1. Prepare if needed
            self.preparePayments(signal)

            //2. Start to Verify
            let verifiedResults = self.verifyReceipts(signal)

            //3. did init
            DispatchQueue.main.async{
                self.banker.didInitializeBank(verifiedResults: verifiedResults, balance: balance)
            }
        }
    }

    private func preparePayments(_ asyncSignal: AsyncWaitSignalable){
        for c in self.registeredCharges{
            (c.payment as? PreparablePayable.Type)?.prepare(asyncSignal)
        }
    }

    @discardableResult
    private func verifyReceipts(_ asyncSignal: AsyncWaitSignalable) -> ChargeableReceiptVerificationResult {
        var valid = Set<ChargeableReceipt>()
        var invalid = Set<ChargeableReceipt>()
        var failed =  Set<ChargeableReceipt>()

        for c in self.registeredCharges{
            guard let r = getReceipt(for: c) else {
                continue
            }

            if let verifiedResult = c.verify(asyncSignal){
                if verifiedResult{
                    valid.insert(r)
                }else{
                    invalid.insert(r)
                }
            }else{
                failed.insert(r)
            }
        }

        return ChargeableReceiptVerificationResult(valid: valid, invalid: invalid, failed: failed)
    }

    func getReceipt(for charge:Chargeable) -> ChargeableReceipt?{
        return self.banker.getReceipt(for: charge)
    }

    @discardableResult
    fileprivate func save(for charge:Charge) -> Bool{
        if let _ = banker.willSaveDeposit(forPriceAmountOf: charge, balance: synchronizedBalance){
            synchronize()
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
