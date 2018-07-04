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
            , willPresentHandler:(() -> ())?=nil
            , didPresentHandler:(() -> ())?=nil
            , willDismissHandler:(() -> ())?=nil
            , didDismissHandler:(() -> ())?=nil){

        let contactViewController = CNContactViewController(forNewContact: newContact)
        let navigationController = UINavigationController(rootViewController: contactViewController)

        let currentQueue = DispatchQueue.current

        if delegator == nil{
            delegator = CNContactViewControllerDelegator()
        }
        delegator?.watch(\.contact) {

            DispatchQueue.main.async {
                willDismissHandler?()

                navigationController.dismiss(animated: true) {
                    didDismissHandler?()

                    currentQueue.async{
                        delegator = nil
                    }
                }
            }
        }

        contactViewController.contactStore = CNContactStore()
        contactViewController.delegate = delegator

        DispatchQueue.main.async {
            willPresentHandler?()
            (onViewController ?? UIApplication.shared.keyWindow?.rootViewController)?.present(navigationController, animated: true) {
                didPresentHandler?()
            }
        }
    }
}