//
// Created by BLACKGENE on 8/24/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol TrialablePayable: Payable{
    static var trialTimeLength:TimeInterval {get}
}

/*
    Trial Control
*/
extension TrialablePayable {
    private static var ExpiredTrialTimeLength:TimeInterval{
        return -Double.greatestFiniteMagnitude
    }

    static func activateTrialIfNeeded(){
        assert(Defaults.shared.remainingTrialPeriod[identifier] == nil, "Already activated trial")
        assert(Defaults.shared.remainingTrialPeriod[identifier] != ExpiredTrialTimeLength, "Expired")

        let t = Defaults.shared.remainingTrialPeriod[identifier]
        if t == nil, t != ExpiredTrialTimeLength {
            Defaults.shared.remainingTrialPeriod[identifier] = trialTimeLength
        }
    }

    static func expireTrialIfNeeded(){
        assert(remainingTrialPeriod != nil, "already invalidated")
        if remainingTrialPeriod != nil{
            Defaults.shared.remainingTrialPeriod[identifier] = ExpiredTrialTimeLength
        }
    }

    static var remainingTrialPeriod:TimeInterval? {
        if let t = Defaults.shared.remainingTrialPeriod[identifier]{
            return t != ExpiredTrialTimeLength ? t : nil
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
