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

        if contact == nil{
            viewController.navigationController?.popViewController(animated: true)
        }
    }

    public func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
}