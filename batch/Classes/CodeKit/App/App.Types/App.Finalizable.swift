//
// Created by BLACKGENE on 28/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


// FinalizableApp
public protocol FinalizableApp:App {
    func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable]
}

extension Array where Element == AppTaskRespondable{
    func isAnyTask(inState:TaskState) -> Bool{
        for e in self{
            if e.info.state == inState{
                return true
            }
        }
        return false
    }

    var defaultTaskPolicy: TaskPolicy{
        return self.first?.appInfo.policy.task ?? TaskPolicy.default
    }
}
