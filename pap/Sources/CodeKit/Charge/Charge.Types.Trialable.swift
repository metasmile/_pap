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

    static var trialTimeLengthLocalizedDayString:String{
        return "%@ Day".localizedFormatted((trialTimeLength/24*60*60).roundedString(toPlaces: 1))
    }

    static var isAvailableToStartTutorial:Bool {
        let t = Defaults.shared.remainingTrialTimeLength[identifier]
        return t == nil
    }

    static func startTrialIfNeeded(){
        assert(Defaults.shared.remainingTrialTimeLength[identifier] == nil, "Already activated trial")
        assert(Defaults.shared.remainingTrialTimeLength[identifier] != ExpiredTrialTimeLength, "Expired")

        let t = Defaults.shared.remainingTrialTimeLength[identifier]
        if t == nil, t != ExpiredTrialTimeLength {
            Defaults.shared.remainingTrialTimeLength[identifier] = trialTimeLength
        }
    }

    static func expireTrialIfNeeded(){
        assert(remainingTrialTimeLength != nil, "already invalidated")
        if remainingTrialTimeLength != nil{
            Defaults.shared.remainingTrialTimeLength[identifier] = ExpiredTrialTimeLength
        }
    }
    
    static var remainingTrialTimeLength:TimeInterval? {
        if let t = Defaults.shared.remainingTrialTimeLength[identifier]{
            return t != ExpiredTrialTimeLength ? t : nil
        }
        return nil
    }
}

private protocol StoreProductInternalDefaults:DefaultsProperty{
    var remainingTrialTimeLength:[String:TimeInterval] {set get}
}

extension Defaults: StoreProductInternalDefaults {
    var remainingTrialTimeLength: [String:TimeInterval] {
        set{ set(newValue) } get{ return get(or:[String:TimeInterval]()) }
    }
}
