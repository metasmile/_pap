//
// Created by BLACKGENE on 28/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol FinalizableApp: App {
    /*
     FinalizableApps basically should affect by shallow cancellation mode. if it is true, can manually control
     */
    func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool

    func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable]
}

extension FinalizableApp{
    public func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool {
        let shouldPreventFinalize = type(of: self).info.policy.task.cancellation == TaskPolicy.Cancellation.shallow
            && result.isAnyTask(inState: .cancelled)
        
        return shouldPreventFinalize == false
    }
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
