//
// Created by BLACKGENE on 03.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

import EventKit
import EventKitUI

extension EKEventEditViewController{

    @discardableResult
    public static func presentDialog(event:EKEvent
            , onViewController:UIViewController?=nil
            , willPresentHandler:(() -> ())?=nil
            , didPresentHandler:(() -> ())?=nil
            , willDismissHandler:((EKEventEditViewAction) -> ())?=nil
            , didDismissHandler:((EKEventEditViewAction) -> ())?=nil) -> EKEventEditViewController{

        let presetingViewController = EKEventEditViewController()
        presetingViewController.event = event
        presetingViewController.eventStore = EventKitUtil.shared.defaultEventStore


//        let navigationController = UINavigationController(rootViewController: presetingViewController)

        let delegator = EKEventEditViewDelegator()

        delegator.watch(\.completedEKEventEditViewAction) {
            DispatchQueue.main.async {
                let completedAction = delegator.completedEKEventEditViewAction.action
                willDismissHandler?(completedAction)

                presetingViewController.dismiss(animated: true) {
                    didDismissHandler?(completedAction)
                }
            }
        }

        presetingViewController.editViewDelegate = delegator

        DispatchQueue.main.async {
            willPresentHandler?()
            (onViewController ?? UIApplication.shared.keyWindow?.rootViewController)?.present(presetingViewController, animated: true) {
                didPresentHandler?()
            }
        }
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
