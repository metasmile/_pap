//
//  AppDelegateShortcutItem.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 31..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

extension UIApplicationShortcutItem {
    static let prefix = "com.stells.shortcutItem"
}

class ShortcutItemAppDelegate: NSObject, UIApplicationDelegate {
    @discardableResult
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            if shortcutItem.type.hasPrefix(UIApplicationShortcutItem.prefix) {
                ShortcutItemAppDelegate.launchAppIfNeededWithShortcutItem(shortcutItem)
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(ShortcutItemAppDelegate.launchAppIfNeededWithShortcutItem(shortcutItem))
    }
}

extension ShortcutItemAppDelegate {
    @discardableResult
    public static func launchAppIfNeededWithShortcutItem(_ shortcutItem:UIApplicationShortcutItem?) -> Bool {
        guard
            let shortcutItem = shortcutItem,
            shortcutItem.type.hasPrefix(UIApplicationShortcutItem.prefix),
            let app = ShortcutItemAppDelegate.findApp(by: shortcutItem)
        else { return false }
        
        AppCenter.default.openApp(identifier: app.info.identifier)
        return true
    }
    
    public static func findApp(by shortcutItem: UIApplicationShortcutItem) -> App.Type? {
        let identifier = shortcutItem.type
        guard identifier.hasPrefix(UIApplicationShortcutItem.prefix) else { return nil }
        
        let appIdentifier = identifier.remove(UIApplicationShortcutItem.prefix)
        
        return AppCenter.default.apps().first (where:{ appType in
            return appType.info.identifier == appIdentifier
        })
    }
    
    public static func appendShortcutItem(by app: App.Type?) {
        guard let app = app else { return }
        
        //TODO:
        // Icons should be square, single color, and 35x35 points, as shown in these template files and as described in Template Images in UIKit User Interface Catalog and in iOS Human Interface Guidelines.
//        let icon = UIApplicationShortcutIcon(templateImageName: app.info.iconBundleName ?? "AppIcon")
        
        let icon = UIApplicationShortcutIcon(type: UIApplicationShortcutIconType.favorite)
        let item = UIApplicationShortcutItem(type: UIApplicationShortcutItem.prefix + app.info.identifier, localizedTitle: app.info.displayName, localizedSubtitle: app.info.description, icon: icon, userInfo: nil)
        
        var items = UIApplication.shared.shortcutItems ?? []
        if let index = items.index(where: { item.type == $0.type }) {
            items.remove(at: index)
        }
        items.append(item)
        UIApplication.shared.shortcutItems = items
    }
}
