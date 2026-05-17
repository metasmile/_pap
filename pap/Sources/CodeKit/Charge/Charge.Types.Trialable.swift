//
// Created by BLACKGENE on 8/24/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol TrialablePayable: Payable{
    static var trialTimeLength:TimeInterval {get}
}

/*
    Trial Control
*/
extension TrialablePayable {
    private static var ExpiredTrialDate:Date{
        return Date(timeIntervalSinceReferenceDate: 0)
    }

    private static var DisabledTrialDate:Date{
        return Date(timeIntervalSinceReferenceDate: 1)
    }

    static var trialTimeLengthLocalizedDayString:String{
        return "%@ Day".localizedFormatted((trialTimeLength/TimeInterval(60.0*60*24)).roundedString(toPlaces: 1))
    }

    static func trial(or pay:(() -> Bool)) -> Bool{
        if isTrialAvailable{
            startTrialIfNeeded()
            return true
        }

        if verifyTrial() == true {
            return true
        }

        if pay(){
            disableTrial()
            return true
        }

        return false
    }

    static func verifyTrial() -> Bool?{
        //Trial has started
        if let d = startedTrialTimeLength, d != DisabledTrialDate {

            //started -> expired
            if d == ExpiredTrialDate{
                return false
            }

            //started -> check
            if Date().timeIntervalSince(d) < trialTimeLength{
                // be continued
                return true

            } else {
                //expire tutorial -> verification fail
                expireTrialIfNeeded()
                return false
            }
        }

        //initial state OR DisabledTrial
        return nil
    }

    static var isTrialAvailable:Bool {
        return Defaults.shared.trialStartedDate[identifier] == nil
    }

    private static func disableTrial(){
        if Defaults.shared.trialStartedDate[identifier] != DisabledTrialDate{
            Defaults.shared.trialStartedDate[identifier] = DisabledTrialDate
        }
    }

    private static var startedTrialTimeLength:Date? {
        return Defaults.shared.trialStartedDate[identifier]
    }

    private static func startTrialIfNeeded(){
        assert(Defaults.shared.trialStartedDate[identifier] == nil, "Already activated trial")
        assert(Defaults.shared.trialStartedDate[identifier] != ExpiredTrialDate, "Expired")

        let t = Defaults.shared.trialStartedDate[identifier]
        if t == nil, t != ExpiredTrialDate {
            Defaults.shared.trialStartedDate[identifier] = Date()
        }
    }

    private static func expireTrialIfNeeded(){
        if startedTrialTimeLength != ExpiredTrialDate{
            Defaults.shared.trialStartedDate[identifier] = ExpiredTrialDate
        }
    }
}

private protocol StoreProductInternalDefaults:PropertyDefaults{
    var trialStartedDate:[String:Date] {set get}
}

extension Defaults: StoreProductInternalDefaults {
    var trialStartedDate: [String:Date] {
        set{ set(newValue) } get{ return get(or:[String:Date]()) }
    }
}
