//
// Created by BLACKGENE on 02.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI

public final class CNContactViewControllerDelegator : NSObject, KeyPathWatchable, CNContactViewControllerDelegate{
    @objc dynamic
    var contact:CNContact?

    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?){
        self.contact = contact
    }

    public func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
}


extension CNContactViewController{

    private static var delegator:CNContactViewControllerDelegator?

    public static func presentDialog(newContact:CNContact
            , onViewController:UIViewController?=nil
            , willPresent:(() -> ())?=nil
            , didPresent:(() -> ())?=nil
            , willDismiss:(() -> ())?=nil
            , didDismiss:(() -> ())?=nil){

        let contactViewController = CNContactViewController(forNewContact: newContact)
        let navigationController = UINavigationController(rootViewController: contactViewController)

        let currentQueue = DispatchQueue.current

        if delegator == nil{
            delegator = CNContactViewControllerDelegator()
        }
        delegator?.watch(\.contact) {
            willDismiss?()

            navigationController.dismiss(animated: true) {
                didDismiss?()

                currentQueue.async{
                    delegator = nil
                }
            }
        }

        contactViewController.contactStore = CNContactStore()
        contactViewController.delegate = delegator

        DispatchQueue.main.async {
            willPresent?()
            (onViewController ?? UIViewController.root)?.present(navigationController, animated: true) {
                didPresent?()
            }
        }
    }
}