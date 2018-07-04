//
// Created by BLACKGENE on 03.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

import EventKit
import EventKitUI

extension EKEventEditViewController{

    @discardableResult
    public static func presentDialog(newEvent:EKEvent
            , onViewController:UIViewController?=nil
            , willPresentHandler:(() -> ())?=nil
            , didPresentHandler:(() -> ())?=nil
            , willDismissHandler:((EKEventEditViewAction) -> ())?=nil
            , didDismissHandler:((EKEventEditViewAction) -> ())?=nil
            , _ asyncSignal:AsyncManualSignalable?=nil
    ) -> EKEventEditViewController{

        let presetingViewController = EKEventEditViewController()
        presetingViewController.event = newEvent
        presetingViewController.eventStore = EventKitUtil.shared.defaultEventStore

        let delegator = EKEventEditViewDelegator()

        let currentQueue = DispatchQueue.current

        delegator.watch(\.completedEKEventEditViewAction) {
            DispatchQueue.main.async {
                let completedAction = delegator.completedEKEventEditViewAction.action
                willDismissHandler?(completedAction)

                presetingViewController.dismiss(animated: true) {
                    currentQueue.async{
                        asyncSignal?.end()
                    }

                    didDismissHandler?(completedAction)
                }
            }
        }

        presetingViewController.editViewDelegate = delegator

        asyncSignal?.begin()
        DispatchQueue.main.async {
            willPresentHandler?()
            (onViewController ?? UIApplication.shared.keyWindow?.rootViewController)?.present(presetingViewController, animated: true) {
                didPresentHandler?()
            }
        }
        asyncSignal?.waitUntilEnd()

        return presetingViewController
    }
}


private class EKEventEditViewActionObject:Object{
    let action:EKEventEditViewAction

    required init(action:EKEventEditViewAction){
        self.action = action
        super.init()
    }
}

private final class EKEventEditViewDelegator: Object, KeyPathWatchable, EKEventEditViewDelegate{

    @objc dynamic
    var completedEKEventEditViewAction = EKEventEditViewActionObject(action: EKEventEditViewAction.canceled)

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.completedEKEventEditViewAction = EKEventEditViewActionObject(action:action)
    }
}
