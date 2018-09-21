//
//  AppIntentable.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 9. 14..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Intents

protocol IntentableApp: App {
    static var intents: [INIntent] { get }
}

extension IntentableApp {
    var isSupportedAddVoiceShortcut: Bool {
        if #available(iOS 12.0, *) {
            return true
        }
        else {
            return false
        }
    }
    
//    func donate() {
//        let interaction = INInteraction(intent: intent, response: nil)
//        interaction.donate(completion: nil)
//    }
//
//    @available(iOS 12.0, *)
//    func setRelevantShortcut(_ relevanceProviders: [INRelevanceProvider]) {
//        if let shortcut = INShortcut(intent: intent) {
//            let relevantShortcut = INRelevantShortcut(shortcut: shortcut)
//            relevantShortcut.shortcutRole = .action
//            relevantShortcut.relevanceProviders = relevanceProviders
//            INRelevantShortcutStore.default.setRelevantShortcuts([relevantShortcut], completionHandler: nil)
//        }
//    }
}

extension INIntent {
    var intentableAppId: String? {
        return value(forKey: "appId") as? String
    }
    
    var intentableLaunchOptions: [AppLaunchOptionsKey: Any]? {
        guard let value = value(forKey: "launchOption") else { return nil }
        return [.IntentLaunchOptionValue: value]
    }
}

extension AppLaunchOptionsKey {
    static var IntentLaunchOptionValue:AppLaunchOptionsKey { return autoKey() }
}
