//
// Created by BLACKGENE on 04.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public class AppTaskPrototypeDefaultRestrictedConcurrency:AppTaskPrototype{

    public required init(_ info: AppTaskInfo) {
        super.init(info)

#if DEBUG
        print("[!] WARNING: estimatedConcurrencyCount is already defined so it will be overridden. Check the configuration at AppInfo.AppPolicy.TaskPolicy")
#endif
    }

    public override var info: AppTaskInfo {
        let info = super.info

        if let param = info.requestParam as? AppAsset{
            let pixelAmount = param.asset.pixelWidth*param.asset.pixelHeight
            if pixelAmount > 3000*3000{
                info.policy.estimatedConcurrencyCount = 1

            }else if pixelAmount > 2000*2000{
                info.policy.estimatedConcurrencyCount = 2

            }else {
                info.policy.estimatedConcurrencyCount = nil
            }
        }else{
            //default is undefined.
            info.policy.estimatedConcurrencyCount = nil
        }

        return info
    }
}