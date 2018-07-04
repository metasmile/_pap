//
// Created by BLACKGENE on 28/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol FinalizableApp: App {
    /*
     INFO:
     FinalizableApps basically should affect by shallow cancellation mode. (a.k.a. TaskPolicy.Cancellation.shallow, TaskPolicy.Cancellation.verbose)

     TaskPolicy.Cancellation.shallow :
        if user cancels just one item at least, all finalization processes will be passed though (ignored).

     TaskPolicy.Cancellation.verbose :
        if user cancels, the finalization process will be go though normally. But in this case, App should manually implement well finalize() method for responsible cancellation.

     WARNING:
        if App implement this, App also MUST manually control for all about cancellation conditions.
     */
    func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool

    func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable]
}

extension FinalizableApp{
    public func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool {
        let shouldPreventFinalize = type(of: self).info.policy.task.cancellation == AppTaskPolicy.Cancellation.shallow
            && result.isAnyTask(inState: .cancelled)
        
        return shouldPreventFinalize == false
    }
}

extension Array where Element == AppTaskRespondable{
    func isAnyTask(inState: AppTaskState) -> Bool{
        for e in self{
            if e.info.state == inState{
                return true
            }
        }
        return false
    }

    var defaultTaskPolicy: AppTaskPolicy {
        return self.first?.appInfo.policy.task ?? AppTaskPolicy.default
    }
}
