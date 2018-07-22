//
//? Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import DefaultsKit
import Contacts
import ContactsUI
import EventKit
import EventKitUI
import UIKit
import SafariServices

public class FinderApp: NSObject, KeyPathWatchable, BApp
        , FinalizableApp
        , AppDockApp
        , PhotoPickerViewControllerDelegatableApp
        , PhotoPickerCollectionViewDisplayableApp
        , PreheatableApp
        , LaunchableApp {

    public static let taskType: AppTaskable.Type = _FinderAppTask.self

    public static let paramType: AppTaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public private(set) lazy var content: AppDockContent? = FinderAppDockContent()

    fileprivate static let privateDefaults = FinderApp.defaults as! FinderAppDefaults

    @objc dynamic
    public lazy var autoSelect: Bool = false

    public static let info = AppInfo(
            identifier: "com.stells.pap.finder"
            , version: "1.0"
            , phase: .release
            , appType: FinderApp.self
            , displayName: "Finder".localized
            , description: "Finder enables extracting every meaningful informations such as phone numbers, addresses, dates or URLs from photos from your photos, and then call, open maps or navigate websites even searh flights!".localized
            , keywords: ["Date", "Address", "Maps", "Location","URL","Flight","E-Mail", "Call", "Phone Number", "Contacts","Text","Detection","Information", "Search","Find","Recognization"]
            , iconBundleName: R.image.finderBAppIcon.name
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
            , minOSVersion: nil
    )

    public required override init() {
        
    }

//    static var callProviderDelegate:CallProviderDelegate?
    class func didConfigurate(with manager: AppManager) {
//        callProviderDelegate = CallProviderDelegate(callManager: CallManager.shared)
    }

    func didResign(current: App.Type?) {

    }

    private var importedLaunchOption:AppLaunchOption?
    func didLaunch(previous: App.Type?, withOption: AppLaunchOption?) {
        importedLaunchOption = withOption
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    public func shouldSelectWhenInserted(indexPaths: [IndexPath]?) -> [IndexPath]? {
        if let _ = importedLaunchOption{
            return indexPaths
        }
        return nil
    }

    fileprivate var preheatCachedResults = [String:FinderAppResult]()
    private var preheatingFrontQueueLabel:String?

    func disposePreheatingCache(){
        if let l = preheatingFrontQueueLabel{
            DispatchQueue(label:l).async{
                self.preheatCachedResults.removeAll()
            }
        }else{
            preheatCachedResults.removeAll()
        }
    }

    public func performPreheating(item: AppAsset, prefetchedImage:PHAssetRequestedImage?, _ async: AsyncWaitSignalable)  -> PreheatingFinishAction? {
        if self.autoSelect == false{
            return nil
        }

        preheatingFrontQueueLabel = async.queueStack.first ?? DispatchQueue.currentLabel

        var preheatedResult:FinderAppResult?

        if let result = preheatCachedResults[item.asset.localIdentifierWithoutSplitter]{
            preheatedResult = result
        }else{
            if let image = item.asset.asUIImage{
                preheatedResult = self.detector.detectResult(asset: item.asset, image: image, async) ?? FinderAppResult(asset: item.asset)
                preheatCachedResults[item.asset.localIdentifierWithoutSplitter] = preheatedResult
            }
        }

        return FinderAppDetector.isResultFilled(result: preheatedResult)
                ? UICollectionViewPreheatableAppFinishAction.selectItem
                : nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        let items = result
                .filter { $0.info.state == .completed }
                .compactMap { $0.result as? FinderAppResult }

        var resultMessage:String?

        switch (FinderApp.privateDefaults.selectionPreset){
            case SelectionPreset.plaintext.rawValue:
                resultMessage = self.finalize_plaintext(items: items, asyncSignal)
            case SelectionPreset.contact.rawValue:
                resultMessage = self.finalize_contact(items: items, asyncSignal)
            case SelectionPreset.action.rawValue:
                resultMessage = self.finalize_action(items: items, asyncSignal)
            default:
                assert(false, "not supported preset \(String(describing: FinderApp.privateDefaults.selectionPreset))")
        }

        if let msg = resultMessage{
            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert(msg, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()
        }

        return result

    }

    public var titleWillBegin: String? {
        return "Starting To Find ...".localized
    }

    public var titleWillFinalize: String? {
        return "Waiting To Select ...".localized
    }

    public func titleDidUpdate(progress: Float) -> String? {
        return "Detecting ... %@ ".localizedFormatted("\(Int(progress * 100))%")
    }

    public var doneButtonTitle: String? {
        return "Find".localized
    }

    fileprivate var detector = FinderAppDetector()
}


private typealias FinderAppParam = PHAssetItem<ImageEditStateValue>

private struct FinderAppResult: AppTaskResultable {
    fileprivate let asset:PHAsset

    init(asset:PHAsset){
        self.asset = asset
    }

    fileprivate var sourceVisionTexts:[VisionText]?

    fileprivate var plainText:String?

    fileprivate var contacts:[VisionTextContactParser.OutputType]?

    fileprivate var resultGroup: VisionTextResultGroup?
}



extension FinderApp{

    fileprivate func finalize_plaintext(items: [FinderAppResult], _ asyncSignal: AsyncWaitSignalable) -> String?{
        let strings = items.compactMap{ $0.plainText }

        if strings.count > 0 {
            asyncSignal.begin()
            DispatchQueue.main.async{
                UIActivityViewController.share(activityItems: strings, excludedActivityTypes: nil) { _, _, _, _ in
                    asyncSignal.end()
                }
            }
            asyncSignal.waitUntilEnd()
            return nil
        }

        return AppMsg.cannot.detect.information
    }

    fileprivate func finalize_contact(items _items: [FinderAppResult], _ asyncSignal: AsyncWaitSignalable) -> String?{
        let items = _items.filter { (item: FinderAppResult) -> Bool in
            if let contacts = item.contacts{
                return contacts.count>0
            }
            return false
        }

        var canSaveContract = items.count > 0

        if false == canSaveContract{
            return AppMsg.cannot.detect.information
        }

        canSaveContract = ContactsUtil.shared.requestAuthorizationAndWait(asyncSignal)

        let errorMessage:String = AppMsg.cannot.save

        if false == canSaveContract{
            return errorMessage
        }

        let saveContactWithoutEdit = FinderApp.privateDefaults.saveContactWithoutEdit

        if saveContactWithoutEdit {
            var savedCount = 0
            for item in items {
                guard let _contacts = item.contacts, _contacts.count > 0 else{
                    continue
                }

                let imageData = item.asset.asData

                for contact in _contacts{
                    autoreleasepool{
                        contact.imageData = imageData

                        let result = ContactsUtil.shared.addContacts(Contact: [contact])
                        if case ContactsUtil.ContactOperationResult.Success(response: true) = result {
                            savedCount += 1
                        }
                    }
                }
            }

            asyncSignal.begin()

            var message = errorMessage
            if savedCount > 0{
                if savedCount == items.count {
                    message = "All contacts were successfully saved.".localized
                }else if savedCount < items.count {
                    message = "Some contacts were saved, but someones were not.".localized
                }
            }
            DispatchQueue.main.async {
                UIAlertController.alert(message, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()

        }else{
            for item in items {
                guard let _contacts = item.contacts, _contacts.count > 0 else{
                    continue
                }
                for contact in _contacts{

                    autoreleasepool{
                        contact.imageData = item.asset.asData

                        asyncSignal.begin()
                        DispatchQueue.main.async{
                            CNContactViewController.presentDialog(newContact: contact, didDismiss: {
                                asyncSignal.end()
                            })
                        }
                        asyncSignal.waitUntilEnd()
                    }
                }
            }
        }

        return nil
    }

    fileprivate func finalize_action(items: [FinderAppResult], _ asyncSignal: AsyncWaitSignalable) -> String?{
        let alert = UIAlertController.actionSheet(title: "Choose An Action".localized, message: nil)

        let defaultCancelSubAction = UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
            asyncSignal.end()
        })

        let isQuickActionOnly = FinderApp.privateDefaults.quickActionOnly

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
            for phoneNumber in Array(Set<String>((resultGroup.phoneNumbers ?? []).reduce([],+).compactMap({ $0.nilEmpty }))) {
                if StringSet.contains(phoneNumber){
                    continue
                } else {
                    StringSet.insert(phoneNumber)
                }

                let _quickAction = { (t:String) -> UIAlertAction in

                    return UIAlertAction(title: t, style: .default, handler: { action in
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
                    })
                }

                var action:UIAlertAction

                if isQuickActionOnly {

                    action = _quickAction(phoneNumber)

                }else{
                    let _alert = UIAlertController.actionSheet(title: actionMessage, message: nil)

                    let _actions = [
                        defaultCancelSubAction,

                        _quickAction("Add New Contact".localized),

                        UIAlertAction(title: "Copy".localized, style: .default, handler: { action in
                            UIPasteboard.general.string = phoneNumber
                            asyncSignal.end()
                        }),
                        UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                            UIActivityViewController.share(activityItems: [phoneNumber], excludedActivityTypes: [UIActivityType.copyToPasteboard]) { type, b, anies, error in
                                asyncSignal.end()
                            }
                        })
                    ]

                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action =  UIAlertAction(title: phoneNumber, style: .default, handler: { action in
                        DispatchQueue.main.async{
                            TableViewController.present(with: [UITableViewCellDescriber(label: "test")])
//                            UIViewController.root?.present(_alert, animated: true)
                        }

                    })
                }

                action.accessoryImage = R.image.ico_action_phonenumber()

                alert.addAction(action)

            }

            /*
                URL
            */
            for url in Array(Set((resultGroup.urls ?? []).reduce([],+))){
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
                            UIActivityViewController.share(activityItems: [url], excludedActivityTypes: [UIActivityType.copyToPasteboard]) { type, b, anies, error in
                                asyncSignal.end()
                            }
                        })
                    ]
                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action = UIAlertAction(title: url.absoluteString, style: . default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.root?.present(_alert, animated: true)
                        }
                    })
                }

                action.accessoryImage = R.image.ico_action_url()

                alert.addAction(action)
            }

            /*
                Date -> Calendar, Reminder
            */
            for date in Array(Set((resultGroup.dates ?? []).reduce([],+))){
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

                                //insert Note with original plain text
                                if let visionTexts = item.sourceVisionTexts{
                                    event.notes = visionTexts.parse(type: VisionTextStringParser.self, asyncSignal)?.joined()
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
                                UIActivityViewController.share(activityItems: [dateString], excludedActivityTypes: [UIActivityType.copyToPasteboard]) { type, b, anies, error in
                                    asyncSignal.end()
                                }
                            })
                    )

                    for _action in _actions{
                        _alert.addAction(_action)
                    }

                    action = UIAlertAction(title: dateString, style: .default, handler: { action in
                        DispatchQueue.main.async{
                            UIViewController.root?.present(_alert, animated: true)
                        }

                    })
                }

                action.accessoryImage = R.image.ico_action_date()

                alert.addAction(action)
            }

            /*
                Email Address -> Email Map app
            */
            for email in Array(Set((resultGroup.emails ?? []).reduce([],+).compactMap({ $0.trimmed.nilEmpty }))){
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
                                UIActivityViewController.share(activityItems: [email], excludedActivityTypes: [UIActivityType.copyToPasteboard]) { type, b, anies, error in
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
                            UIViewController.root?.present(_alert, animated: true)
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
                        , "x-source":Bundle.main.displayName ?? ""
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
                                UIActivityViewController.share(activityItems: [addressString], excludedActivityTypes: [UIActivityType.copyToPasteboard]) { type, b, anies, error in
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
                            UIViewController.root?.present(_alert, animated: true)
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
            for flightString in Array(Set((resultGroup.flights ?? []).reduce([],+).compactMap({ $0.nilEmpty }))){
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
                                UIActivityViewController.share(activityItems: [flightString], excludedActivityTypes: [UIActivityType.copyToPasteboard]) { type, b, anies, error in
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
                            UIViewController.root?.present(_alert, animated: true)
                        }
                    })
                }

                action?.accessoryImage = R.image.ico_action_flightnumber()

                if let action = action{
                    alert.addAction(action)
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
                UIViewController.root?.present(alert, animated: true)
            }

            asyncSignal.waitUntilEnd()

            return nil
        }

        return AppMsg.cannot.detect.information
    }

}

private struct FinderAppDetector{

    private let vision = Vision.vision()

    fileprivate static func isResultFilled(result:FinderAppResult?) -> Bool{
        let preset = FinderApp.privateDefaults.selectionPreset

        if preset == SelectionPreset.plaintext.rawValue{
            return result?.plainText?.count ?? 0 > 0
        }

        if preset == SelectionPreset.action.rawValue{
            return result?.resultGroup?.isFilled == true
        }

        if preset == SelectionPreset.contact.rawValue{
            return result?.contacts?.count ?? 0 > 0
        }

        return false
    }


    fileprivate func detectResult(asset:PHAsset, image: UIImage, _ async: AsyncWaitSignalable) -> FinderAppResult? {
        guard let visionTexts = vision.textDetector().detect(with: image, async) else {
            return nil
        }

        let preset = FinderApp.privateDefaults.selectionPreset
        var defaults = FinderApp.privateDefaults
        let selectedParserTypes = Set((defaults.selectedParserCollection.values).reduce([],+))

        var result = FinderAppResult(asset: asset)

        result.sourceVisionTexts = visionTexts

        // SelectionPreset.plaintext
        if preset == SelectionPreset.plaintext.rawValue{
            result.plainText = visionTexts.parse(type: VisionTextStringParser.self, async)?.joined()
        }

        // SelectionPreset.contact,  SelectionPreset.action
        else if preset == SelectionPreset.contact.rawValue {
            var parser = VisionTextContactParser()
            var parserTypes:NSTextCheckingResult.CheckingType = []

            parser.parseLinkAsEmailAddress = selectedParserTypes.contains(ParserItem.Key.EmailAddress)

            if selectedParserTypes.contains(ParserItem.Key.PhoneNumber){
                parserTypes.insert(.phoneNumber)
            }

            if selectedParserTypes.contains(ParserItem.Key.URL){
                parserTypes.insert(.link)
            }

            if selectedParserTypes.contains(ParserItem.Key.Address){
                parserTypes.insert(.address)
            }

            if selectedParserTypes.contains(ParserItem.Key.Date){
                parserTypes.insert(.date)
            }

            if selectedParserTypes.contains(ParserItem.Key.FlightNumber){
                parserTypes.insert(.transitInformation)
            }

            parser.types = parserTypes

            var stackedParsedContacts = [CNMutableContact]()

            for visionText in visionTexts{

                var mergingContract:CNMutableContact?
                if stackedParsedContacts.count == 0{
                    mergingContract = CNMutableContact()
                }else{
                    mergingContract = stackedParsedContacts.last
                }

                if let mergingContract = mergingContract
                , let parsedContract = parser.process(input: visionText, mergingOutput: mergingContract){
                    stackedParsedContacts.append(parsedContract)
                }
            }

            if let lastParsedContact = stackedParsedContacts.last{
                result.contacts = [lastParsedContact]
            }
        }

        else if preset == SelectionPreset.action.rawValue{

            var resultGroup = VisionTextResultGroup()

            if selectedParserTypes.contains(ParserItem.Key.EmailAddress){
                resultGroup.emails = visionTexts.parse(type: VisionTextEmailAddressParser.self, async)
            }

            if selectedParserTypes.contains(ParserItem.Key.PhoneNumber){
                resultGroup.phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async)
            }

            if selectedParserTypes.contains(ParserItem.Key.URL){
                if let urls = visionTexts.parse(type: VisionTextURLParser.self, async){
                    //excluding mail addresses
                    resultGroup.urls = urls.compactMap { $0.compactMap { $0.scheme == "mailto" ? nil : $0 }.nilEmpty }
                }
            }

            if selectedParserTypes.contains(ParserItem.Key.Address){
                resultGroup.addresses = visionTexts.parse(type: VisionTextAddressParser.self, async)
            }

            if selectedParserTypes.contains(ParserItem.Key.FlightNumber){
                resultGroup.flights = visionTexts.parse(type: VisionTextFlightNumberParser.self, async)
            }

            if selectedParserTypes.contains(ParserItem.Key.Date){
                resultGroup.dates = visionTexts.parse(type: VisionTextDateParser.self, async)
            }

            result.resultGroup = resultGroup

        }else{
            assert(false, "current preset mode is not supported. \(String(describing: preset))")
            return nil
        }

        return result
    }
}

private class _FinderAppTask: AppTaskPrototypeDefaultConcurrencyCountPolicy, AppTaskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {

        guard let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset else{
            return nil
        }

        if let preheatedResults = AppCenter.default.currentInstanceAs(FinderApp.self)?.preheatCachedResults
        , let result = preheatedResults[asset.localIdentifierWithoutSplitter] {
            return result

        }else if let image = asset.asUIImage{

            let detector = AppCenter.default.currentInstanceAs(FinderApp.self)?.detector
            return detector?.detectResult(asset: asset, image: image, async)
        }

        return nil
    }
}


/*

AppContent

*/

private enum SelectionPreset:Int{
    case action
    case contact
    case plaintext
}

private enum FinderAppSettingCells {
    case takePhoto
    case presets
    case autoSelect
    case saveContactWithoutEdit
    case quickActionOnly
//    case delete
}

private struct SettingsItem {
    fileprivate var key: FinderAppSettingCells
    fileprivate var label:String
    fileprivate var valueGetter:() -> Any
    fileprivate var valueCollection:Any?
    fileprivate var valueHandler:((Any) -> ())?
    fileprivate var cellDescriber: UITableViewCellDescribable //TODO: integrate all properties
    fileprivate var iconImageName:String?
}

private protocol FinderAppDefaults: AppDefaults{
    var selectedParserCollection: ParserCollection {get set}
    var selectionPreset: Int {get set}
    var saveContactWithoutEdit:Bool {get set}
    var quickActionOnly:Bool {get set}
}

extension Defaults: FinderAppDefaults {
    fileprivate var selectedParserCollection: ParserCollection {
        set{ set(newValue) }
        get{ return get(or: ParserDictionary.DefaultCollection) }
    }

    fileprivate var selectionPreset: Int {
        set{ set(newValue) }
        get{ return get(or: SelectionPreset.action.rawValue ) }
    }

    fileprivate var saveContactWithoutEdit: Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }

    fileprivate var quickActionOnly: Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }
}


extension FinderAppDefaults{
    fileprivate func addHandledProperty(_ dictionary:ParserDictionary.Key, _ property:ParserItem.Key){

        var immutableSelf = self
        if immutableSelf.selectedParserCollection[dictionary] == nil{
            immutableSelf.selectedParserCollection = ParserCollection()
            var p = immutableSelf.selectedParserCollection
            p[dictionary] = [property]
            immutableSelf.selectedParserCollection = p
        }else{
            if selectedParserCollection[dictionary]?.contains(property) == false{
                var p = immutableSelf.selectedParserCollection
                p[dictionary]?.append(property)
                immutableSelf.selectedParserCollection = p
            }
        }
    }

    fileprivate func removeHandledProperty(_ dictionary:ParserDictionary.Key, _ property:ParserItem.Key){

        if let index = selectedParserCollection[dictionary]?.index(of: property){
            var immutableSelf = self
            var p = immutableSelf.selectedParserCollection
            p[dictionary]?.remove(at: index)
            immutableSelf.selectedParserCollection = p
        }
    }
}

private typealias ParserCollection = [ParserDictionary.Key: [ParserItem.Key]]

private struct ParserItem {
    enum Key: Int, Codable {
        case PhoneNumber
        case EmailAddress
        case Address

        case Date
        case URL

        case FlightNumber
        case GPSCoordinates
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var iconImageBundleName:String?
}

private struct ParserDictionary {

    static let DefaultCollection: ParserCollection = [
        ParserDictionary.Key.Information: [
            ParserItem.Key.PhoneNumber
            ,ParserItem.Key.EmailAddress
            ,ParserItem.Key.Address

            ,ParserItem.Key.Date
            ,ParserItem.Key.URL
            ,ParserItem.Key.FlightNumber
        ]
    ]

    enum Key: Int, Codable {
        case Information
    }

    fileprivate var key:Key
    fileprivate var label:String
    fileprivate var items:[ParserItem]
}

fileprivate class FinderAppDockContent: NSObject, AppDockContent, UITableViewDelegate, UITableViewDataSource, UITableViewPickerCellDelegate{
    private lazy var tintColor = UIColor(red:0.36, green:0.31, blue:0.71, alpha:1)

    fileprivate var settingCellDescribers = [UITableViewCellDefaultDescribable]()

    private var parserCollection:[ParserDictionary] {
        get{
            if FinderApp.privateDefaults.selectionPreset == SelectionPreset.plaintext.rawValue{
                return []
            }

            return type(of: self).defaultParserCollection
        }
    }

    fileprivate static let defaultParserCollection:[ParserDictionary] = [

        ParserDictionary(key: ParserDictionary.Key.Information, label: "Items".localized,
                items: [
                    ParserItem(key: ParserItem.Key.PhoneNumber, label:"Phone Number".localized, iconImageBundleName:R.image.ico_action_phonenumber.name)
                    ,ParserItem(key: ParserItem.Key.EmailAddress, label:"E-mail Address".localized, iconImageBundleName:R.image.ico_action_email.name)
                    ,ParserItem(key: ParserItem.Key.Address, label:"Address".localized, iconImageBundleName:R.image.ico_action_address.name)
                    ,ParserItem(key: ParserItem.Key.Date, label:"Date".localized, iconImageBundleName:R.image.ico_action_date.name)
                    ,ParserItem(key: ParserItem.Key.URL, label:"URL", iconImageBundleName:R.image.ico_action_url.name)
                    ,ParserItem(key: ParserItem.Key.FlightNumber, label:"Flight Number".localized, iconImageBundleName:R.image.ico_action_flightnumber.name)
                ])
    ]

    required public override init() {
        super.init()
    }

    private var initialSelectedIndexPaths:[IndexPath]?

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tintColor = tintColor
        return tableView
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 300
        return preferences
    }

    private var selectedParserCollection: ParserCollection{
        return FinderApp.privateDefaults.selectedParserCollection
    }

    private var autoSelect:Bool = false


    private func createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit() -> UITableViewSwitchCellDescriber{
        let celld = UITableViewSwitchCellDescriber()
        celld.itemIdentifier = FinderAppSettingCells.saveContactWithoutEdit.hashValue
        celld.label = "Save Found Contacts Directly".localized
        celld.valueGetter = { FinderApp.privateDefaults.saveContactWithoutEdit }
        celld.valueHandler = {
            var defaults = FinderApp.privateDefaults
            defaults.saveContactWithoutEdit = $0 as! Bool
        }
        return celld
    }

    private func createCellDescriber_SelectionPreset_action_quickActionsOnly() -> UITableViewSwitchCellDescriber{
        let celld = UITableViewSwitchCellDescriber()
        celld.itemIdentifier = FinderAppSettingCells.quickActionOnly.hashValue
        celld.label = "Quick Actions Only".localized
        celld.valueGetter = { FinderApp.privateDefaults.quickActionOnly }
        celld.valueHandler = {
            var defaults = FinderApp.privateDefaults
            defaults.quickActionOnly = $0 as! Bool
        }
        return celld
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

        if settingCellDescribers.count>0{
            return
        }

        let cell1 = UITableViewSwitchCellDescriber()
        cell1.itemIdentifier = FinderAppSettingCells.autoSelect.hashValue
        cell1.label = "Enable Auto Selection".localized
        cell1.valueGetter = { self.autoSelect }
        cell1.iconImage = R.image.commonIconRobot.name
        cell1.valueHandler = {
            self.autoSelect = $0 as! Bool
            AppCenter.default.currentInstanceAs(FinderApp.self)?.autoSelect = self.autoSelect
        }
        settingCellDescribers.append(cell1)

        let cell_b = UITableViewButtonCellDescriber()
        cell_b.itemIdentifier = FinderAppSettingCells.takePhoto.hashValue
        cell_b.label = "Take A Photo".localized
        cell_b.buttonImageName = R.image.systemIconCamera.name
        cell_b.valueHandler = { _ in
            var option = AppLaunchOption()
            option.identifierToReturn = FinderApp.info.identifier

            AppCenter.default.openApp(identifier:"com.stells.pap.camera", options:option)

        }
        settingCellDescribers.append(cell_b)


        let cell0 = UITableViewSegmentControlCellDescriber()
        cell0.itemIdentifier = FinderAppSettingCells.presets.hashValue
        cell0.label = "Formats".localized
        cell0.valueGetter = { FinderApp.privateDefaults.selectionPreset }
        cell0.valueCollection = [
            (label:"Actions".localized,value: SelectionPreset.action.rawValue),
            (label:"Contacts".localized,value: SelectionPreset.contact.rawValue),
            (label:"Plain Text".localized,value: SelectionPreset.plaintext.rawValue)
        ]
        cell0.valueHandler = {
            let preset = $0 as! Int

            var defaults = FinderApp.privateDefaults
            defaults.selectionPreset = preset

            // selectionPreset changed -> other self.parserCollection getter will be returned.
            (view as? UITableView)?.reloadData()


            [
                FinderAppSettingCells.saveContactWithoutEdit.hashValue
                , FinderAppSettingCells.quickActionOnly.hashValue
            ].forEach { hashValue in

                if let index = self.settingCellDescribers.index(where:{ describable in
                    return describable.itemIdentifier == hashValue
                }){
                    self.settingCellDescribers.remove(at: index)
                }
            }

            //saveContactWithoutEdit
            if preset == SelectionPreset.contact.rawValue{
                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
            }

            if preset == SelectionPreset.action.rawValue{
                self.settingCellDescribers.append(self.createCellDescriber_SelectionPreset_action_quickActionsOnly())
            }

            (view as? UITableView)?.reloadData()

            // autoSelect turn off and restore
            cell1.valueHandler?(false)

            //remove preheating cache
            AppCenter.default.currentInstanceAs(FinderApp.self)?.disposePreheatingCache()

        }
        settingCellDescribers.append(cell0)

        //auto save
        if FinderApp.privateDefaults.selectionPreset == SelectionPreset.contact.rawValue{
            settingCellDescribers.append(createCellDescriber_SelectionPreset_contact_saveContactWithoutEdit())
        }
        else if FinderApp.privateDefaults.selectionPreset == SelectionPreset.action.rawValue{
            settingCellDescribers.append(createCellDescriber_SelectionPreset_action_quickActionsOnly())
        }

        if let tableView = view as? UITableView{
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 44
            tableView.allowsSelection = false
            tableView.allowsMultipleSelection = false
            tableView.register(Cell.self, forCellReuseIdentifier: FinderApp.info.identifier)

            for desc in settingCellDescribers {
                tableView.register(describer: desc)
            }
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {

        let defaultsCollection = FinderApp.privateDefaults.selectedParserCollection

        //get indexes
        let sections = self.parserCollection.enumerated().compactMap { (section, dictionary) -> [IndexPath]? in
            if let handledItems = defaultsCollection[dictionary.key]{

                return handledItems.compactMap { key -> IndexPath? in
                    guard let item = dictionary.items.index(where: { item -> Bool in
                        return key == item.key
                    }) else{
                        return nil
                    }
                    return IndexPath(item: item, section: 1+section)
                }
            }
            return nil
        }


        //init initialSelectedIndexPaths
        initialSelectedIndexPaths = [IndexPath]()
        for indexPaths in sections{
            initialSelectedIndexPaths?.append(contentsOf: indexPaths)
        }

        (view as! UITableView).reloadData()

        initialSelectedIndexPaths = nil
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + parserCollection.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let label_section0 = "Select Photos To Find Everything.".localized
        return section == 0 ? label_section0 : parserCollection[section-1].label
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? settingCellDescribers.count : parserCollection[section-1].items.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = indexPath.section == 0 ? settings_tableView(tableView, cellForRowAt: indexPath) : parserCollection_tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: indexPath.section))
        return cell
    }

    func settings_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.settingCellDescribers[indexPath.item]

        if let cellDescriber = item as? UITableViewPickerCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [String]
        , let cell: UITableViewPickerCell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewPickerCell {

            cell.values = valueCollection
            cell.delegate = self
            if let value = item.valueGetter() as? String ?? valueCollection.first, let index = valueCollection.index(of: value){
                cell.selectedRow = index
            } else{
                cell.selectedRow = 0
            }
            cell.titleLabel.text = item.label
            return cell

        }

        else if let cellDescriber = item as? UITableViewSwitchCellDescriber
        , let value = item.valueGetter() as? Bool
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSwitchCell {

            cell.textLabel?.text = item.label
            cell.switcher.setOn(value, animated: false)
            cell.switcher.onTintColor = self.view.tintColor
            if let image = item.iconImage?.asUIImage{
                cell.imageView?.image = image.withRenderingMode(.alwaysTemplate)
                cell.imageView?.tintColor = self.view.tintColor
            }
            cell.switchDidChange = item.valueHandler
            return cell
        }

        else if let cellDescriber = item as? UITableViewButtonCellDescriber
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewButtonCell {

            cell.textLabel?.text = item.label

            if let buttonAsImage = cellDescriber.buttonImageName?.asUIImage{
                cell.button.setImage(buttonAsImage.withRenderingMode(.alwaysTemplate), for: .normal)
            }else if let buttonAsText = cellDescriber.buttonTitleLabel {
                cell.button.setTitle(buttonAsText, for: .normal)
                cell.button.setTitleColor(self.view.tintColor, for: .selected)
                cell.button.setTitleColor(self.view.tintColor, for: .highlighted)
            }
            cell.button.tintColor = self.view.tintColor
            cell.imageView?.image = item.iconImage?.asUIImage?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = self.view.tintColor
            cell.didTap = {
                cellDescriber.valueHandler?(true)
            }
            cell.button.layoutIfNeeded()
            return cell
        }

        else if let cellDescriber = item as? UITableViewStepperCellDescriber
        , let value = item.valueGetter() as? Int
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewStepperCell {

            cell.textLabel?.text = item.label
            cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(value)
            cell.imageView?.image = item.iconImage?.asUIImage

            cell.stepper.stepValue = cellDescriber.stepValue
            cell.stepper.minimumValue = cellDescriber.minimumValue
            cell.stepper.maximumValue = cellDescriber.maximumValue
            cell.stepper.value = Double(value)

            cell.didChangeValue = { value in
                cell.detailTextLabel?.text = cellDescriber.valuePresenter?(value) ?? String(Int(value))
                item.valueHandler?(value)
            }
            return cell
        }

        else if let cellDescriber = item as? UITableViewSegmentControlCellDescriber
        , let valueCollection = cellDescriber.valueCollection as? [(String, Int)]
        , let cell = tableView.dequeueReusableCell(withIdentifier: cellDescriber.cellIdentifier) as? UITableViewSegmentedControlCell{

            cell.textLabel?.text = item.label
            cell.imageView?.image = item.iconImage?.asUIImage

            cell.segmentedControl.removeAllSegments()

            for (label, _) in valueCollection{
                cell.segmentedControl.insertSegment(withTitle: label, at: cell.segmentedControl.numberOfSegments, animated: false)
            }

            cell.segmentedControl.selectedSegmentIndex = valueCollection.index { t in
                t.1 == (item.valueGetter() as! Int)
            } ?? 0

            cell.didChangeValue = item.valueHandler
            return cell
        }

        let cell = tableView.cellForRow(at: indexPath) ?? UITableViewCell()
        cell.textLabel?.text = item.label
        return cell
    }

    func parserCollection_tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let dict = self.parserCollection[indexPath.section-1]

        var selected = false
        if let _ = initialSelectedIndexPaths?.index(of: indexPath) {
            selected = true
        }
        if let _ = FinderApp.privateDefaults.selectedParserCollection[dict.key]?.index(of: dict.items[indexPath.item].key){
            selected = true
        }

        let dataItem = dict.items[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: FinderApp.info.identifier) as! Cell
        cell.textLabel?.text = dataItem.label
        cell.detailTextLabel?.text = selected ? "%@ might be found".localizedFormatted("").trimmed : nil

        cell.imageView?.tintColor = self.view.tintColor
        let image = dataItem.iconImageBundleName?.asUIImageNamed
        cell.imageView?.image = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)

        cell.detailTextLabel?.textColor = UIColor.gray
        cell.optionSwitch.setOn(selected, animated: false)
        cell.switchDidChange = { on in

            AppCenter.default.currentInstanceAs(FinderApp.self)?.disposePreheatingCache()

            if on{
                FinderApp.privateDefaults.addHandledProperty(dict.key, dict.items[indexPath.item].key)
            }else{
                FinderApp.privateDefaults.removeHandledProperty(dict.key, dict.items[indexPath.item].key)
            }

            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        return cell
    }

    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any) {

    }
}

private class Cell: UITableViewCell {
    lazy var optionSwitch: UISwitch = {
        let view = UISwitch()
        view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
        return view
    }()

    var switchDidChange: ((Bool) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()

        switchDidChange = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryView = optionSwitch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        optionSwitch.onTintColor = tintColor
    }
}
