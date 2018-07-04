//
// Created by BLACKGENE on 02.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI

extension CNContactViewController{

    @discardableResult
    public static func presentDialog(contact:CNContact
            , onViewController:UIViewController?=nil
            , willPresentHandler:(() -> ())?=nil
            , didPresentHandler:(() -> ())?=nil
            , willDismissHandler:(() -> ())?=nil
            , didDismissHandler:(() -> ())?=nil) -> CNContactViewController{

        let contactViewController = CNContactViewController(forNewContact: contact)
        let navigationController = UINavigationController(rootViewController: contactViewController)

        let delegator = CNContactViewControllerDelegator()

        delegator.watch(\.completedContact) {
            willDismissHandler?()

            navigationController.dismiss(animated: true) {
                didDismissHandler?()
            }
        }

        contactViewController.contactStore = CNContactStore()
        contactViewController.delegate = delegator

        willPresentHandler?()
        (onViewController ?? UIApplication.shared.keyWindow?.rootViewController)?.present(navigationController, animated: true) {
            didPresentHandler?()
        }

        return contactViewController
    }
}


private final class CNContactViewControllerDelegator : NSObject, KeyPathWatchable, CNContactViewControllerDelegate{
    @objc dynamic
    var completedContact:CNContact?

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?){
        completedContact = contact
    }

    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
}