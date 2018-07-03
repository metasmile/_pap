//
// Created by BLACKGENE on 02.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI

public final class CNContactViewControllerDelegator : NSObject, KeyPathWatchable, CNContactViewControllerDelegate{
    @objc dynamic
    var completedContact:CNContact?

    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?){
        completedContact = contact
    }

    public func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
}


extension CNContactViewController{

    public static func presentCreationDialog(contact:CNContact
            , onViewController:UIViewController?=nil
            , willPresentHandler:(() -> ())?=nil
            , didPresentHandler:(() -> ())?=nil
            , willDismissHandler:(() -> ())?=nil
            , didDismissHandler:(() -> ())?=nil
            , _ asyncSignal:AsyncManualSignalable?=nil){

        let contactViewController = CNContactViewController(forNewContact: contact)
        let navigationController = UINavigationController(rootViewController: contactViewController)

        let delegator = CNContactViewControllerDelegator()
        let currentQueue = DispatchQueue.current

        delegator.watch(\.completedContact) {
            DispatchQueue.main.async {
                willDismissHandler?()

                navigationController.dismiss(animated: true) {

                    if let signal = asyncSignal{
                        currentQueue.async{
                            signal.end()
                        }
                    }

                    didDismissHandler?()
                }
            }
        }

        contactViewController.contactStore = CNContactStore()
        contactViewController.delegate = delegator

        asyncSignal?.begin()
        DispatchQueue.main.async {
            willPresentHandler?()
            (onViewController ?? UIApplication.shared.keyWindow?.rootViewController)?.present(navigationController, animated: true) {
                didPresentHandler?()
            }
        }
        asyncSignal?.waitUntilEnd()
    }
}