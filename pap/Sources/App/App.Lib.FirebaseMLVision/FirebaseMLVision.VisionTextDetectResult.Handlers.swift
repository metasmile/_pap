//
// Created by BLACKGENE on 2018-09-28.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Contacts
import ContactsUI
import EventKit
import EventKitUI
import SafariServices

//TODO: MUST separate each actions

extension Array where Element:VisionTextDetectResult {

    func handleAsAction(_ isQuickActionOnly:Bool, _ asyncSignal: AsyncWaitSignalable) -> String?{

        let items: [VisionTextDetectResult] = self
        let currentQueue = DispatchQueue.current

        let alert = UIAlertController.actionSheet(title: "Choose An Action".localized, message: nil)

        let defaultCancelSubAction = UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
            asyncSignal.end()
        })

        var StringSet = Set<String>()
        var DateSet = Set<Date>()
        var URLSet = Set<URL>()

        for item in items {

            guard let resultGroup = item.resultGroup else{
                continue
            }

            let actionMessage = "Choose An Sub Action.".localized

            /*
                Phone Number
            */
            for phoneNumber in Array<VisionTextPhoneNumberParser.OutputType.Element>(Set<String>((resultGroup.phoneNumbers ?? []).reduce([],+).compactMap({ $0.nilEmpty }))) {
                if StringSet.contains(phoneNumber){
                    continue
                } else {
                    StringSet.insert(phoneNumber)
                }

                let phoneNumberActionContactsSaving = { (t:String) -> UIAlertAction in

                    return UIAlertAction(title: t, style: .default, handler: { action in

                        currentQueue.async{
                            if ContactsUtil.shared.requestAuthorizationAndWait(asyncSignal){
                                let contact = CNMutableContact()
                                contact.contactType = .person
                                contact.fillNameIfBlanked()

                                let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                                contact.dates.append(CNLabeledValue(label: "Date".localized, value: components as NSDateComponents))
                                contact.urlAddresses.append(CNLabeledValue(label: "URL", value: "https://apps.photo"))
                                contact.phoneNumbers = [ CNLabeledValue(label: "Phone Number".localized, value: CNPhoneNumber(stringValue: phoneNumber))]

                                CNContactViewController.presentDialog(newContact: contact, didDismiss: {
                                    asyncSignal.end()
                                })

                            }else{
                                asyncSignal.end()
                            }
                        }
                    })
                }

                let phoneNumberActionCall = { (t:String) -> UIAlertAction in

                    return UIAlertAction(title: t, style: .default, handler: { action in

                        if let url = URL(string: "tel://\(phoneNumber)")
                        , ContactsUtil.shared.isCapableToCall
                        , UIApplication.shared.canOpenURL(url) {

                            asyncSignal.end()

                            if #available(iOS 10, *) {
                                UIApplication.shared.open(url)
                            } else {
                                UIApplication.shared.openURL(url)
                            }

                        }else{
                            asyncSignal.end()
                        }
                    })
                }

                var action:UIAlertAction

                if isQuickActionOnly {

                    action = phoneNumberActionCall(phoneNumber)

                }else{
                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)

                    let _actions = [
                        defaultCancelSubAction,

                        phoneNumberActionCall("Making A Call".localized),

                        phoneNumberActionContactsSaving("Add New Contact".localized),

                        UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                            UIPasteboard.general.string = phoneNumber
                            asyncSignal.end()
                        }),
                        UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                            UIActivityViewController.share(activityItems: [phoneNumber], excludedActivityTypes: [UIActivity.ActivityType.copyToPasteboard]) { type, b, anies, error in
                                asyncSignal.end()
                            }
                        })
                    ]

                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action =  UIAlertAction(title: phoneNumber, style: .default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.present(_alert, animated: true)
                        }

                    })
                }

                action.accessoryImage = R.image.ico_action_phonenumber()

                alert.addAction(action)

            }

            /*
                URL
            */
            for url in Array<VisionTextURLParser.OutputType.Element>(Set((resultGroup.urls ?? []).reduce([],+))){
                if URLSet.contains(url){
                    continue
                } else {
                    URLSet.insert(url)
                }

                //sub actions
                let _quickAction = { (t: String) -> UIAlertAction in
                    return UIAlertAction(title: t, style: .default, handler: { action in
                        UIApplication.openSafari(with:url) {
                            asyncSignal.end()
                        }
                    })
                }


                var action:UIAlertAction

                if isQuickActionOnly{

                    action = _quickAction(url.absoluteString)

                }else{


                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)
                    let _actions = [
                        defaultCancelSubAction,

                        _quickAction("Open Web Page".localized),

                        UIAlertAction(title: "Add New Contact".localized, style: .default, handler: { action in
                            if ContactsUtil.shared.requestAuthorizationAndWait(asyncSignal){
                                let contact = CNMutableContact()
                                contact.contactType = .person
                                contact.fillNameIfBlanked()

                                let components = NSCalendar.current.dateComponents([.year, .month, .day], from: Date())
                                contact.dates.append(CNLabeledValue(label: "Date".localized, value: components as NSDateComponents))

                                contact.urlAddresses.append(CNLabeledValue(label: "URL", value: url.absoluteString as NSString))

                                CNContactViewController.presentDialog(newContact: contact, didDismiss: {
                                    asyncSignal.end()
                                })

                            }else{
                                asyncSignal.end()
                            }
                        }),

                        UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                            UIPasteboard.general.url = url
                            asyncSignal.end()
                        }),
                        UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                            UIActivityViewController.share(activityItems: [url], excludedActivityTypes: [UIActivity.ActivityType.copyToPasteboard]) { type, b, anies, error in
                                asyncSignal.end()
                            }
                        })
                    ]
                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action = UIAlertAction(title: url.absoluteString, style: . default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.present(_alert, animated: true)
                        }
                    })
                }

                action.accessoryImage = R.image.ico_action_url()

                alert.addAction(action)
            }

            /*
                Date -> Calendar, Reminder
            */
            for date in Array<VisionTextDateParser.OutputType.Element>(Set((resultGroup.dates ?? []).reduce([],+))){
                if DateSet.contains(date){
                    continue
                } else {
                    DateSet.insert(date)
                }

                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .medium
                let dateString = formatter.string(from: date)

                //sub actions
                let _quickAction = { (t: String) -> UIAlertAction in
                    return UIAlertAction(title: t, style: .default, handler: { action in

                        EventKitUtil.shared.newEvent { event in

                            if let event = event{
                                event.title = "New Event".localized
                                event.startDate = date
                                event.endDate = date

                                //insert Note with original plain text
                                if let visionTexts = item.sourceVisionTexts{

                                    let syncParser = VisionTextStringParser()
                                    event.notes = visionTexts.compactMap { syncParser.process(input: $0) }.joined()
                                }

                                EKEventEditViewController.presentDialog(newEvent: event, didDismiss: { action in
                                    asyncSignal.end()
                                })

                            }else{
                                asyncSignal.end()
                            }
                        }
                    })
                }


                var action:UIAlertAction

                if isQuickActionOnly{

                    action  = _quickAction(dateString)

                }else{
                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)
                    var _actions = [defaultCancelSubAction]

                    _actions.append(
                            _quickAction("Add an Event".localized)
                    )

                    _actions.append(
                            UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                                UIPasteboard.general.string = dateString
                                asyncSignal.end()
                            })
                    )

                    _actions.append(
                            UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                                UIActivityViewController.share(activityItems: [dateString], excludedActivityTypes: [UIActivity.ActivityType.copyToPasteboard]) { type, b, anies, error in
                                    asyncSignal.end()
                                }
                            })
                    )

                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action = UIAlertAction(title: dateString, style: .default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.present(_alert, animated: true)
                        }

                    })
                }

                action.accessoryImage = R.image.ico_action_date()

                alert.addAction(action)
            }

            /*
                Email Address -> Email Map app
            */
            for email in Array<VisionTextEmailAddressParser.OutputType.Element>(Set((resultGroup.emails ?? []).reduce([],+).compactMap({ $0.trimmed.nilEmpty }))){
                if StringSet.contains(email){
                    continue
                } else {
                    StringSet.insert(email)
                }


                //sub actions

                let _quickAction = { (t: String) -> UIAlertAction? in

                    if let url = URL(string: "mailto://\(email)")
                    , UIApplication.shared.canOpenURL(url){
                        return UIAlertAction(title: t, style: .default, handler: { action in
                            asyncSignal.end()
                            UIApplication.shared.open(url)
                        })
                    }

                    return nil
                }

                var action:UIAlertAction?

                if isQuickActionOnly{
                    action = _quickAction(email)


                }else{
                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)

                    var _actions = [defaultCancelSubAction]

                    if let q = _quickAction("Send an Email".localized){
                        _actions.append(q)
                    }

                    let param = [
                        "to": email
                    ].urlQueryString

                    let url_gmail = URL(string: "googlegmail://co?\(param)")
                    if let url = url_gmail, UIApplication.shared.canOpenURL(url){
                        _actions.append(
                                UIAlertAction(title: "Send an Email".localized + " (Gmail)", style: .default, handler: { action in
                                    asyncSignal.end()
                                    UIApplication.shared.open(url)
                                })
                        )
                    }

                    let url_inbox = URL(string: "inbox-gmail://co?\(param)")
                    if let url = url_inbox, UIApplication.shared.canOpenURL(url){
                        _actions.append(
                                UIAlertAction(title: "Send an Email".localized + " (Google Inbox)", style: .default, handler: { action in
                                    asyncSignal.end()
                                    UIApplication.shared.open(url)
                                })
                        )
                    }

                    _actions.append(
                            UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                                UIPasteboard.general.string = email
                                asyncSignal.end()
                            })
                    )

                    _actions.append(
                            UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                                UIActivityViewController.share(activityItems: [email], excludedActivityTypes: [UIActivity.ActivityType.copyToPasteboard]) { type, b, anies, error in
                                    asyncSignal.end()
                                }
                            })
                    )

                    _actions.append(
                            UIAlertAction(title: "Add New Contact".localized, style: .default, handler: { action in

                                if ContactsUtil.shared.requestAuthorizationAndWait(asyncSignal){
                                    let contact = CNMutableContact()
                                    contact.contactType = .person
                                    contact.fillNameIfBlanked()

                                    let components = NSCalendar.current.dateComponents([.year, .month, .day], from: Date())
                                    contact.dates.append(CNLabeledValue(label: "Date".localized, value: components as NSDateComponents))
                                    contact.emailAddresses = [CNLabeledValue(label: "E-mail Address".localized, value: email as NSString)]

                                    CNContactViewController.presentDialog(newContact: contact, didDismiss: {
                                        asyncSignal.end()
                                    })

                                }else{
                                    asyncSignal.end()
                                }
                            })
                    )

                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action = UIAlertAction(title: email, style: .default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.present(_alert, animated: true)
                        }
                    })
                }

                action?.accessoryImage = R.image.ico_action_email()

                if let action = action{
                    alert.addAction(action)
                }
            }

            /*
                Address -> Map
            */
            //comgooglemaps://?saddr=Google+Inc,+8th+Avenue,+New+York,+NY&daddr=John+F.+Kennedy+International+Airport,+Van+Wyck+Expressway,+Jamaica,+New+York&directionsmode=transit
            // https://developers.google.com/maps/documentation/urls/ios-urlscheme
            // https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/MapLinks/MapLinks.html#//apple_ref/doc/uid/TP40007899-CH5-SW1

            for addr in (resultGroup.addresses ?? []).reduce([],+){
                let addressString = addr.formattedString.trimmed

                if StringSet.contains(addressString){
                    continue
                } else {
                    StringSet.insert(addressString)
                }

                //sub actions
                let _quickAction = { (t: String) -> UIAlertAction? in
                    if let url = URL(string: "http://maps.apple.com/?\(["q":addressString].urlQueryString))")
                    , UIApplication.shared.canOpenURL(url){

                        return UIAlertAction(title: t, style: .default, handler: { action in
                            asyncSignal.end()
                            UIApplication.shared.open(url)
                        })
                    }

                    return nil
                }

                var action:UIAlertAction?

                if isQuickActionOnly{

                    action = _quickAction(addressString)

                }else{

                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)

                    var _actions = [defaultCancelSubAction]

                    if let q = _quickAction("Open Apple Maps".localized){
                        _actions.append(q)
                    }

                    let param_googlemap = [
                        "q":addressString
                        , "x-success": Bundle.main.schemes?.first ?? ""
                        , "x-source": papStrings.name
                    ].urlQueryString

                    let url_googlemap = URL(string: "comgooglemaps-x-callback://?\(param_googlemap)")

                    if let url = url_googlemap, UIApplication.shared.canOpenURL(url){
                        _actions.append(
                                UIAlertAction(title: "Open Google Maps".localized, style: .default, handler: { action in
                                    asyncSignal.end()
                                    UIApplication.shared.open(url)
                                })
                        )
                    }

                    _actions.append(
                            UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                                UIPasteboard.general.string = addressString
                                asyncSignal.end()
                            })
                    )

                    _actions.append(
                            UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                                UIActivityViewController.share(activityItems: [addressString], excludedActivityTypes: [UIActivity.ActivityType.copyToPasteboard]) { type, b, anies, error in
                                    asyncSignal.end()
                                }
                            })
                    )

                    _actions.append(
                            UIAlertAction(title: "Add New Contact".localized, style: .default, handler: { action in

                                if ContactsUtil.shared.requestAuthorizationAndWait(asyncSignal){
                                    let contact = CNMutableContact()
                                    contact.contactType = .person
                                    contact.fillNameIfBlanked()

                                    let components = NSCalendar.current.dateComponents([.year, .month, .day], from: Date())
                                    contact.dates.append(CNLabeledValue(label: "Date".localized, value: components as NSDateComponents))

                                    contact.postalAddresses = [CNLabeledValue(label: "Address", value: addr.postalAddress)]

                                    CNContactViewController.presentDialog(newContact: contact, didDismiss: {
                                        asyncSignal.end()
                                    })

                                }else{
                                    asyncSignal.end()
                                }
                            })
                    )

                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action = UIAlertAction(title: addressString, style: . default, handler: { action in

                        DispatchQueue.main.async{
                            UIViewController.present(_alert, animated: true)
                        }
                    })

                }

                action?.accessoryImage = R.image.ico_action_address()

                if let action = action{
                    alert.addAction(action)
                }

            }// END OF AN ACTION


            /*
                Flight Information
            */
            for flightString in Array<VisionTextFlightNumberParser.OutputType.Element>(Set((resultGroup.flights ?? []).reduce([],+).compactMap({ $0.nilEmpty }))){
                if StringSet.contains(flightString){
                    continue
                } else {
                    StringSet.insert(flightString)
                }

                var action:UIAlertAction?

                let url_to_flight = URL(string: "https://flightaware.com/live/flight/"+flightString.encodeAsURLQuery())

                let _quickAction = { (t: String) -> UIAlertAction? in
                    if let url = url_to_flight, UIApplication.shared.canOpenURL(url){
                        return UIAlertAction(title: t, style: .default, handler: { action in
                            UIApplication.openSafari(with:url) {
                                asyncSignal.end()
                            }
                        })
                    }
                    return nil
                }

                if isQuickActionOnly{
                    action = _quickAction(flightString)

                }else{
                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)

                    var _actions = [defaultCancelSubAction]

                    if let q = _quickAction("Search Flights".localized){
                        _actions.append(q)
                    }

                    _actions.append(
                            UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                                UIPasteboard.general.string = flightString
                                asyncSignal.end()
                            })
                    )

                    _actions.append(
                            UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                                UIActivityViewController.share(activityItems: [flightString], excludedActivityTypes: [UIActivity.ActivityType.copyToPasteboard]) { type, b, anies, error in
                                    asyncSignal.end()
                                }
                            })
                    )

                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    //root action
                    action = UIAlertAction(title: flightString, style: . default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.present(_alert, animated: true)
                        }
                    })
                }

                action?.accessoryImage = R.image.ico_action_flightnumber()

                if let action = action{
                    alert.addAction(action)
                }

            }// END OF AN ACTION
            
            
            /*
             Plain Text
             */
            if let plainText = item.plainText?.trimmed {
                var action:UIAlertAction?
                
                //sub actions
                let _quickAction = { (t: String) -> UIAlertAction? in
                    return UIAlertAction(title: t, style: .default, handler: { action in
                        UIActivityViewController.share(activityItems: [plainText], excludedActivityTypes: nil) { type, b, anies, error in
                            asyncSignal.end()
                        }
                    })
                }
                
                if isQuickActionOnly{
                    action = _quickAction(plainText.components(separatedBy: .newlines).joined())
                    
                }else{
                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)
                    
                    var _actions = [defaultCancelSubAction]
                    
                    if let q = _quickAction("Share".localized){
                        _actions.append(q)
                    }
                    
                    _actions.append(
                        UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                            UIPasteboard.general.string = plainText
                            asyncSignal.end()
                        })
                    )
                    
                    for _action in _actions{
                        _alert.addAction(_action)
                    }
                    
                    //root action
                    action = UIAlertAction(title: plainText.components(separatedBy: .newlines).joined(), style: . default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.present(_alert, animated: true)
                        }
                    })
                }
                
                if let action = action{
                    action.accessoryImage = R.image.commonCellIconShare()
                    alert.addAction(action)
                }
            }// END OF AN ACTION


            /*
             Barcodes
             */
            for barcode in resultGroup.barcodes ?? [] {
                switch barcode.valueType {
                case .URL: break
                case .text, .unknown:
                    let plainText = barcode.rawValue ?? ""
                    var action:UIAlertAction?
                    
                    //sub actions
                    let _quickAction = { (t: String) -> UIAlertAction? in
                        return UIAlertAction(title: t, style: .default, handler: { action in
                            UIActivityViewController.share(activityItems: [plainText], excludedActivityTypes: nil) { type, b, anies, error in
                                asyncSignal.end()
                            }
                        })
                    }
                    
                    if isQuickActionOnly{
                        action = _quickAction(plainText.components(separatedBy: .newlines).joined())
                        
                    }else{
                        let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)
                        
                        var _actions = [defaultCancelSubAction]
                        
                        if let q = _quickAction("Share".localized){
                            _actions.append(q)
                        }
                        
                        _actions.append(
                            UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                                UIPasteboard.general.string = plainText
                                asyncSignal.end()
                            })
                        )
                        
                        for _action in _actions{
                            _alert.addAction(_action)
                        }
                        
                        //root action
                        action = UIAlertAction(title: plainText.components(separatedBy: .newlines).joined(), style: . default, handler: { action in
                            DispatchQueue.main.async{
                                UIViewController.present(_alert, animated: true)
                            }
                        })
                    }
                    
                    if let action = action{
                        action.accessoryImage = R.image.commonCellIconShare()
                        alert.addAction(action)
                    }
                    default: break
                }
            }// END OF AN ACTION
        }// END OF ITEMS


        //ACTION START
        if alert.actions.count > 0{
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
                asyncSignal.end()
            }))

            asyncSignal.begin()

            DispatchQueue.main.async{
                UIViewController.present(alert, animated: true)
            }

            asyncSignal.waitUntilEnd()

            return nil
        }

        return "Could not detect anything.".localized
    }
}
