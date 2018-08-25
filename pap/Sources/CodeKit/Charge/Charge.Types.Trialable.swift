//
// Created by BLACKGENE on 8/24/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

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

    static var trialTimeLengthLocalizedDayString:String{
        return "%@ Day".localizedFormatted((trialTimeLength/TimeInterval(60.0*60*24)).roundedString(toPlaces: 1))
    }

    static func tryTrial() -> Bool{
        if isAvailableToStartTutorial{
            startTrialIfNeeded()
            return true
        }

        if verifyTrial() {
            return true
        }

        return false
    }

    static func verifyTrial() -> Bool{
        if let tutorialStartedDate = startedTrialTimeLength, Date().timeIntervalSince(tutorialStartedDate) < trialTimeLength{
            return true
        }
        expireTrialIfNeeded()
        return false
    }

    static var isAvailableToStartTutorial:Bool {
        let t = Defaults.shared.trialStartedDate[identifier]
        return t == nil
    }

    private static var startedTrialTimeLength:Date? {
        if let t = Defaults.shared.trialStartedDate[identifier]{
            return t != ExpiredTrialDate ? t : nil
        }
        return nil
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
