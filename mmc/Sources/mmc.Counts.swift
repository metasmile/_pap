//
// Created by BLACKGENE on 8/27/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//INFO: com.stells.mmc-exclusive time interval policies in strict seconds.
//CRITICAL
struct mmcCounts {

    static var defaultAllowedOfflineAdsSkipCountInCurrentRuntime:Int{
#if DEBUG
        return 1
#else
        return 5
#endif
    }

}