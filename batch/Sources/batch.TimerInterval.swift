//
// Created by BLACKGENE on 8/27/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//INFO: com.stells.batch-exclusive time interval policies in strict seconds.
//CRITICAL

#if DEBUG
private let debugMode = true
#endif

struct batchTimeInterval {

    static var ofTimeOfUsesDayTimeUnit:TimeInterval{
        #if DEBUG
        if debugMode{
            return 8
        }
        #endif
        return 60*60*24
    }

    static var ofAllTimeAppPaymentTrialTimeLength:TimeInterval{
        #if DEBUG
        if debugMode{
            return 30
        }
        #endif
        return 60*60*24*1
    }

    static var ofGADInterestialTypeBlockOfUses:TimeInterval{
        #if DEBUG
        if debugMode{
            return 30
        }
        #endif
        return 60*10
    }

    static var ofSNSEngagementPaymentLatestPaid:TimeInterval{
        #if DEBUG
        if debugMode{
            return 30
        }
        #endif
        return 60*60*24*14
    }

    static var ofFBShareTypeDownloadMessagerPaymentLatestPaid:TimeInterval{
        #if DEBUG
        if debugMode{
            return 30
        }
        #endif
        return 60*60*24*14
    }
}