//
// Created by BLACKGENE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

protocol Payable {
    static var charge: Chargeable {get}

    func pay(_ asyncSignal:AsyncWaitSignalable) -> Bool

    init()
}

enum ChargeType:Int, Codable {
    //promotional
    case inStoreRating
    case onPromptRating
    case socialShare
    case feedback
    case ads

    //paid
    case nonConsumablePurchase
    case consumablePurchase
    case nonRenewingMonthlySubscription
    case nonRenewingYearlySubscription
    case renewableMonthlySubscription
    case renewableYearlySubscription
}

enum RewardType:Int, Codable {
    case timeOfUses
    case countOfUses
    case owned
}

protocol Chargeable {
    var type: ChargeType {set get}
    var reward:RewardType {set get}
}

extension Chargeable{
    func isEqual(other:Chargeable) -> Bool{
        return reward==other.reward && type==other.type
    }
}

protocol Charge: Chargeable {
    var price: Double {get}

    var title:String {get}
    var description:String? {get}
}

class ChargeManager: NSObject, KeyPathWatchable{

    private let payingQueue:DispatchQueue = DispatchQueue(label: String(describing: ChargeManager.self))
    private var defaults: ChargeDefaults

    private let charges:[Charge] // type: price

    init(charges:[Charge]){
        self.charges = charges
        self.defaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: type(of: self))+"UserDefaults") ?? UserDefaults.standard)
        self.balance = self.defaults.balance
    }

    //INFO: watchable + read-only.
    @objc dynamic
    private(set) var balance:Double {
        didSet{
            defaults.balance = balance
        }
    }

    func resetBalance(){
#if DEBUG
        print("[i]INFO: In the release build, balance resetting will not be performed.")
        balance = 0
#endif
    }

    func getCharge(for payable: Payable.Type) -> Charge?{
        return charges.first { item in
            return (item as Chargeable).isEqual(other: payable.charge)
        }
    }

    func getRemainingCharges(cheapFirst:Bool=false) -> [Charge]{
        if balance==1{
            return []
        }

        let cheapFirstItems = charges.sorted { (item: Charge, item2: Charge) -> Bool in
            return item.price < item2.price
        }
        var remainingCharges = [Charge]()
        var bal = self.balance
        for item in cheapFirstItems {
            bal += item.price
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
        if let price = getCharge(for: payable)?.price{
            let currentBalance = self.balance
            payingQueue.async{
                if payable.init().pay(asyncSignal){

                    DispatchQueue.main.async{
                        self.balance += clamp(price, 0, 1-currentBalance)
                    }
                }else{
                    print("[!]WARNING: payment failed \(String(describing: payable))")
                }
            }
        }
    }

    func isPaid(for payable:Payable.Type) -> Bool{
        //TODO: consumption unit date, app use count etc.
        return balance > getCharge(for: payable)?.price ?? 0
    }
}

/*
Private Interfaces
*/

private protocol ChargeDefaults:DefaultsProperty{
    var balance: Double {set get}
}

extension Defaults: ChargeDefaults {
    fileprivate var balance: Double {
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

