//
// Created by BLACKGENE on 02.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Contacts

#if os(OSX)
import Cocoa
import CoreTelephony
#elseif os(iOS)
import UIKit
import CoreTelephony
#endif

public struct ContactsUtil {
    public static let shared = ContactsUtil()

    public func requestAccess(_ requestGranted: @escaping (Bool) -> ()) {
        CNContactStore().requestAccess(for: .contacts) { grandted, _ in
            requestGranted(grandted)
        }
    }

    public var authorizationStatus: CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }

    public func requestAuthorizationAndWait(_ asyncSignal: AsyncWaitSignalable) -> Bool{
        var canSaveContract = false

        let status = ContactsUtil.shared.authorizationStatus
        /*
            /*! The user has not yet made a choice regarding whether the application may access contact data. */
            case notDetermined

            /*! The application is not authorized` to access contact data.
             *  The user cannot change this application’s status, possibly due to active restrictions such as parental controls being in place. */
            case restricted

            /*! The user explicitly denied access to contact data for the application. */
            case denied

            /*! The application is authorized to access contact data. */
            case authorized
            */

        if status == CNAuthorizationStatus.notDetermined{
            asyncSignal.begin()
            ContactsUtil.shared.requestAccess { granted in
                canSaveContract = granted
                asyncSignal.end()
            }
            asyncSignal.waitUntilEnd()
        }
        else if status == CNAuthorizationStatus.authorized{
            canSaveContract = true

        }else{
            asyncSignal.begin()
            DispatchQueue.main.async{
                UIAlertController.alert("It requires a permission to access your contacts. Please allow Contacts on iOS Settings.".localized, completion: { action in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()
        }

        return canSaveContract
    }

    public enum ContactsFetchResult {
        case Success(response: [CNContact])
        case Error(error: Error)
    }

    public func fetchContacts() -> ContactsFetchResult {

        let contactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let fetchRequest: CNContactFetchRequest = CNContactFetchRequest(keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
        do {
            try contactStore.enumerateContacts(with: fetchRequest, usingBlock: {
                contact, _ in
                contacts.append(contact) })

            return ContactsFetchResult.Success(response: contacts)
        } catch {
            return ContactsFetchResult.Error(error: error)
        }
    }

    @available(iOS 10.0, *)
    public func fetchContacts(sortOrder: CNContactSortOrder) ->  ContactsFetchResult {

        let contactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let fetchRequest: CNContactFetchRequest = CNContactFetchRequest(keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
        fetchRequest.unifyResults = true
        fetchRequest.sortOrder = sortOrder
        do {
            try contactStore.enumerateContacts(with: fetchRequest, usingBlock: {
                contact, _ in
                contacts.append(contact) })
            return ContactsFetchResult.Success(response: contacts)
        } catch {
            return ContactsFetchResult.Error(error: error)
        }
    }


    public func searchContact(SearchString string: String) ->  ContactsFetchResult {

        let contactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: string)
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
            return ContactsFetchResult.Success(response: contacts)
        } catch {
            return ContactsFetchResult.Error(error: error)
        }
    }

    public enum ContactFetchResult {
        case Success(response: CNContact)
        case Error(error: Error)
    }

    public func getContactFromID(Identifires identifiers: [String]) ->  ContactsFetchResult {

        let contactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        let predicate: NSPredicate = CNContact.predicateForContacts(withIdentifiers: identifiers)
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
            return ContactsFetchResult.Success(response: contacts)
        } catch {
            return ContactsFetchResult.Error(error: error)
        }
    }

    public enum ContactOperationResult {
        case Success(response: Bool)
        case Error(error: Error)
    }

#if os(iOS) || os(OSX)
    public func addContacts(Contact contacts: [CNMutableContact]) ->  ContactOperationResult {
        let store = CNContactStore()
        let request = CNSaveRequest()

        for contact in contacts{
            request.add(contact, toContainerWithIdentifier: nil)
        }

        do {
            try store.execute(request)
            return ContactOperationResult.Success(response: true)
        } catch {
            print(error)
            return ContactOperationResult.Error(error: error)
        }
    }
#endif

#if os(iOS) || os(OSX)
    public func addContactInContainer(contact: CNMutableContact, Container_Identifier identifier: String) ->  ContactOperationResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        request.add(contact, toContainerWithIdentifier: identifier)
        do {
            try store.execute(request)
            return ContactOperationResult.Success(response: true)
        } catch {
            return ContactOperationResult.Error(error: error)
        }
    }

    public func updateContact(contact: CNMutableContact) ->  ContactOperationResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        request.update(contact)
        do {
            try store.execute(request)
            return ContactOperationResult.Success(response: true)
        } catch {
            return ContactOperationResult.Error(error: error)
        }
    }

    public func deleteContact(contact: CNMutableContact) ->  ContactOperationResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        request.delete(contact)
        do {
            try store.execute(request)
            return ContactOperationResult.Success(response: true)
        } catch {
            return ContactOperationResult.Error(error: error)
        }
    }
#endif

    public enum GroupsFetchResult {
        case Success(response: [CNGroup])
        case Error(error: Error)
    }

    public func fetchGroups() -> GroupsFetchResult {
        let store = CNContactStore()
        do {
            let groups: [CNGroup] = try store.groups(matching: nil)
            return GroupsFetchResult.Success(response: groups)
        } catch {
            return GroupsFetchResult.Error(error: error)
        }
    }

    public enum GroupsOperationsResult {
        case Success(response: Bool)
        case Error(error: Error)
    }

#if os(iOS) || os(OSX)
    public func createGroup(Group_Name name: String) ->  GroupsOperationsResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        let group: CNMutableGroup = CNMutableGroup()
        group.name = name
        request.add(group, toContainerWithIdentifier: nil)
        do {
            try store.execute(request)
            return GroupsOperationsResult.Success(response: true)
        } catch {
            return GroupsOperationsResult.Error(error: error)
        }
    }

    public func createGroupInContainer(Group_Name name: String, ContainerIdentifire identifire: String) ->  GroupsOperationsResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        let group: CNMutableGroup = CNMutableGroup()
        group.name = name
        request.add(group, toContainerWithIdentifier: identifire)
        do {
            try store.execute(request)
            return GroupsOperationsResult.Success(response: true)
        } catch {
            return GroupsOperationsResult.Error(error: error)
        }
    }

    public func removeGroup(group: CNGroup) ->  GroupsOperationsResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        if let mutableGroup: CNMutableGroup = group.mutableCopy() as? CNMutableGroup {
            request.delete(mutableGroup)
        }
        do {
            try store.execute(request)
            return GroupsOperationsResult.Success(response: true)
        } catch {
            return GroupsOperationsResult.Error(error: error)
        }
    }

    public func updateGroup(group: CNGroup, New_Group_Name name: String) ->  GroupsOperationsResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        if let mutableGroup: CNMutableGroup = group.mutableCopy() as? CNMutableGroup {
            mutableGroup.name = name
            request.update(mutableGroup)
        }
        do {
            try store.execute(request)
            return GroupsOperationsResult.Success(response: true)
        } catch {
            return GroupsOperationsResult.Error(error: error)
        }
    }

    public func addContactToGroup(group: CNGroup, Contact contact: CNContact) ->  GroupsOperationsResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        request.addMember(contact, to: group)
        do {
            try store.execute(request)
            return GroupsOperationsResult.Success(response: true)
        } catch {
            return GroupsOperationsResult.Error(error: error)
        }
    }

    public func removeContactFromGroup(group: CNGroup, Contact contact: CNContact) ->  GroupsOperationsResult {
        let store = CNContactStore()
        let request = CNSaveRequest()
        request.removeMember(contact, from: group)
        do {
            try store.execute(request)
            return GroupsOperationsResult.Success(response: true)
        } catch {
            return GroupsOperationsResult.Error(error: error)
        }
    }
#endif

    public func fetchContactsIn(group: CNGroup) ->  ContactsFetchResult {

        let contactStore = CNContactStore()
        var contacts: [CNContact] = [CNContact]()
        do {
            let predicate: NSPredicate = CNContact.predicateForContactsInGroup(withIdentifier: group.name)
            let keysToFetch: [String] = [CNContactGivenNameKey]
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch as [CNKeyDescriptor])
            return ContactsFetchResult.Success(response: contacts)
        } catch {
            return ContactsFetchResult.Error(error: error)
        }
    }

    public func fetchAllContactsIn(group: CNGroup) ->  ContactsFetchResult {

        let contactStore = CNContactStore()
        let contacts = [CNContact]()
        do {
            var predicate: NSPredicate!
            let allGroups: [CNGroup] = try contactStore.groups(matching: nil)
            for item in allGroups {
                if item.name == group.name {
                    predicate = CNContact.predicateForContactsInGroup(withIdentifier: group.identifier)
                }
            }
            let keysToFetch: [String] = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactUrlAddressesKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactNoteKey, CNContactImageDataKey]
            if predicate != nil {
                var contacts: [CNContact] = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch as [CNKeyDescriptor])
                for contact in contacts {
                    contacts.append(contact)
                }
            }
            return ContactsFetchResult.Success(response: contacts)
        } catch {
            return ContactsFetchResult.Error(error: error)
        }
    }



#if os(OSX)

    public func CNPhoneNumberToString(number: CNPhoneNumber) -> String {
        if let result: String = CNPhoneNumber.value(forKey: "digits") as? String {
            return result
        }
        return ""
    }

    public func makeCall(number: CNPhoneNumber) {
        if let phoneNumber: String = CNPhoneNumber.value(forKey: "digits") as? String {
            guard let url: URL = URL(string: "tel://" + "\(phoneNumber)") else {
                print("Error in Making Call")
                return
            }
            NSWorkspace.shared.open(url)
        }

    }

#elseif os(iOS)
    public var isCapableToCall:Bool {
        if UIApplication.shared.canOpenURL(NSURL(string: "tel://")! as URL) {
            // Check if iOS Device supports phone calls
            // User will get an alert error when they will try to make a phone call in airplane mode
            if let mnc: String = CTTelephonyNetworkInfo().subscriberCellularProvider?.mobileNetworkCode, !mnc.isEmpty {
                // iOS Device is capable for making calls
                return true
            }
        }

        return false
    }

    public var isCapableToSMS:Bool{
        return UIApplication.shared.canOpenURL(NSURL(string: "sms:")! as URL)
    }

    public func CNPhoneNumberToString(number: CNPhoneNumber) -> String {
        if let result: String = CNPhoneNumber.value(forKey: "digits") as? String {
            return result
        }
        return ""
    }

    public func makeCall(number: CNPhoneNumber) {
        if let phoneNumber: String = CNPhoneNumber.value(forKey: "digits") as? String {
            guard let url: URL = URL(string: "tel://" + "\(phoneNumber)") else {
                print("Error in Making Call")
                return
            }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url)
            }
        }
    }

#endif
}

extension Data {
    public var asContacts:[CNContact]? {
        return try? CNContactVCardSerialization.contacts(with: self) as [CNContact]
    }
}

extension Array where Element==CNContact{

    public var vCard: Data? {
        return try? CNContactVCardSerialization.data(with: self)
    }
}

extension CNMutableContact{

    @discardableResult
    public func fillNameIfBlanked() -> Bool{
        let isNameEmpty = self.familyName.count == 0
                && self.givenName.count == 0
                && self.nickname.count == 0
                && self.middleName.count == 0

        if isNameEmpty{
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .medium

            self.givenName = "\("New Contact".localized): \(formatter.string(from: Date()))"
        }
        return isNameEmpty
    }
}