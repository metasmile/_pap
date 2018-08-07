//
// Created by BLACKGENE on 31.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import CoreSpotlight
import UIKit

private let LocalizableKeywordPrefix = "cs_keyword_"
private let LocalizableKeywordLastIndexNumber = 13;

private extension Array where Element==CSSearchable{
    var searchableItems:[CSSearchableItem]{
        return self.map { $0.createItem() }
    }
}

public struct CSSearchable {
    static let prefix = "com.stells.corespotlight"

    let suffix:String
    var attributeSet:CSSearchableItemAttributeSet? = nil
    var domain:String? = "default"

    var identifier:String{
        return type(of: self).prefix + suffix
    }

    func createItem() -> CSSearchableItem {
       let item = CSSearchableItem()
        item.uniqueIdentifier = self.identifier
        item.domainIdentifier = self.domain
        if let attr = self.attributeSet{
            item.attributeSet = attr
        }
        return item
    }

    init(suffix:String, domain:String?=nil, attributeSet:CSSearchableItemAttributeSet?=nil){
        self.suffix = suffix
        self.domain = domain
        self.attributeSet = attributeSet
    }
}

extension CSSearchable{
    init(app:App.Type){

        let csItemAttr = CSSearchableItemAttributeSet(itemContentType: UTI.image.rawValue)
        csItemAttr.title = app.info.displayName
        csItemAttr.contentDescription = app.info.description
        csItemAttr.keywords = app.info.keywords
        if let image = app.info.iconBundleName?.asUIImage{
            autoreleasepool {
                var thumbnailImage = image
                if let rImage = image.rounded(radius: image.size.height/2){
                    thumbnailImage = rImage
                }
                csItemAttr.thumbnailData = thumbnailImage.pngData()
            }
        }
        self.init(suffix: app.info.identifier, domain: String(describing: App.self), attributeSet: csItemAttr)
    }

    public static func appBySearchable(activity:NSUserActivity) -> App.Type? {
        guard activity.activityType == CSSearchableItemActionType
        , let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        , identifier.hasPrefix(CSSearchable.prefix) else {
            return nil
        }

        let appIdentifier = identifier.remove(CSSearchable.prefix)

        return AppCenter.default.apps().first (where:{ appType in
            return appType.info.identifier == appIdentifier
        })
    }
}


class SpotlightSearchAppDelegate: NSObject, UIApplicationDelegate{

    static var selectedUserActivity:NSUserActivity?

    @discardableResult
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let activityDictionary = launchOptions?[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] { //Universal link

            for key in activityDictionary.keys {
                if let userActivity = activityDictionary[key] as? NSUserActivity {

                    if let _ = CSSearchable.appBySearchable(activity: userActivity){
                        SpotlightSearchAppDelegate.selectedUserActivity = userActivity
                        SpotlightSearchAppDelegate.launchAppIfNeededWithSearchable()
                        break
                    }

                }
            }
        }


        return true
    }

    @discardableResult
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        SpotlightSearchAppDelegate.selectedUserActivity = userActivity
        SpotlightSearchAppDelegate.launchAppIfNeededWithSearchable()
        return true
    }

    @discardableResult
    public static func launchAppIfNeededWithSearchable(activity:NSUserActivity?=SpotlightSearchAppDelegate.selectedUserActivity) -> Bool{

        guard let activity = activity
        , activity.activityType == CSSearchableItemActionType
        , let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        , identifier.hasPrefix(CSSearchable.prefix) else {
            return false
        }

        guard let app = CSSearchable.appBySearchable(activity: activity) else {
            return false
        }

        AppCenter.default.openApp(identifier: app.info.identifier)
        return true
    }

    func indexDefaultSearchableItems(){
        var items = [CSSearchable]()

        //main item
        let csItemAttr = CSSearchableItemAttributeSet(itemContentType: UTI.image.rawValue)
        csItemAttr.title = papStrings.name
        csItemAttr.contentDescription = papStrings.title
        csItemAttr.keywords = Array(0 ... LocalizableKeywordLastIndexNumber).map { e -> String in
            return (LocalizableKeywordPrefix+String(e)).localized
        }
        items.append(CSSearchable(suffix: ".main"))

        //apps
        let appItems = AppCenter.default.apps(by: AppQuery.default).map { appType -> CSSearchable in
//            (appType as? PersistableApp.Type)?.status
            return CSSearchable(app:appType)
        }
        items.append(contentsOf: appItems)

        CSSearchableIndex.default().indexSearchableItems(items.searchableItems) { error in
            assert(error==nil, "indexSearchableItems has an error.")
        }
    }
}
