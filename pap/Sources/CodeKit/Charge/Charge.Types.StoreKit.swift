//
// Created by BLACKGENE on 8/14/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import StoreKit
import DefaultsKit

protocol StorePayable: VerifiablePayable {
    static var product: StoreProduct {get}

    static var storeProduct:SKProduct? {get}

    static func fetchStoreProduct(_ signal:AsyncWaitSignalable) -> Bool
}

struct StoreProduct {
    let identifier:String
    let subscriptionPeriod: Period?
    let trialTimeLength:TimeInterval?

    init(identifier:String, subscriptionPeriod:Period?, trialTimeLength:TimeInterval?=nil){
        self.identifier = identifier
        self.subscriptionPeriod = subscriptionPeriod
        self.trialTimeLength = trialTimeLength
    }
}

/*
    Trial Control
*/
extension StoreProduct{
    private var ExpiredTrialLength:TimeInterval{
        return -Double.greatestFiniteMagnitude
    }

    func activateTrialIfNeeded(){
        assert(trialTimeLength != nil, "This product not configured trialTimeLength")
        assert(Defaults.shared.remainingTrialPeriod[identifier] == nil, "Already activated trial")
        assert(Defaults.shared.remainingTrialPeriod[identifier] != ExpiredTrialLength, "Expired")

        let t = Defaults.shared.remainingTrialPeriod[identifier]
        if let trialLength = trialTimeLength, t == nil, t != ExpiredTrialLength{
            Defaults.shared.remainingTrialPeriod[identifier] = trialLength
        }
    }

    func expireTrialIfNeeded(){
        assert(remainingTrialPeriod != nil, "already invalidated")
        if remainingTrialPeriod != nil{
            Defaults.shared.remainingTrialPeriod[identifier] = ExpiredTrialLength
        }
    }

    var remainingTrialPeriod:TimeInterval? {
        if let _ = trialTimeLength, let t = Defaults.shared.remainingTrialPeriod[identifier]{
            return t != ExpiredTrialLength ? t : nil
        }
        return nil
    }
}

private protocol StoreProductInternalDefaults:DefaultsProperty{
    var remainingTrialPeriod:[String:TimeInterval] {set get}
}

extension Defaults: StoreProductInternalDefaults {
    var remainingTrialPeriod: [String:TimeInterval] {
        set{ set(newValue) } get{ return get(or:[String:TimeInterval]()) }
    }
}
