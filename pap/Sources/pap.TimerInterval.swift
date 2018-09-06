//
// Created by BLACKGENE on 8/27/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//INFO: com.stells.pap-exclusive time interval policies in strict seconds.
//CRITICAL
struct papTimeInterval{

    static var ofTimeOfUsesDayTimeUnit:TimeInterval{
#if DEBUG
        return 8
#else
        return 60*60*24
#endif

    }

    static var ofAllTimeAppPaymentTrialTimeLength:TimeInterval{
#if DEBUG
        return 30
#else
        return 60*60*24*3
#endif
    }

    static var ofGADInterestialTypeBlockOfUses:TimeInterval{
#if DEBUG
        return 30
#else
        return 60*60*3
#endif
    }

    static var ofSNSEngagementPaymentLatestPaid:TimeInterval{
#if DEBUG
        return 10
#else
        return 60*60*24*5
#endif
    }

    static var ofFBShareTypeDownloadMessagerPaymentLatestPaid:TimeInterval{
#if DEBUG
        return 10
#else
        return 60*60*24*7
#endif
    }

}