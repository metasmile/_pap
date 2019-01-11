//
// Created by BLACKGENE on 2019-01-11.
// Copyright (c) 2019 Stells. All rights reserved.
//

import Foundation
import Intents
import UIKit

extension UIApplicationDelegateLaunchableApp where Self:App{
    static var intents: [INIntent] {
        return defaultIntents
    }

    static var defaultIntents:[INIntent]{
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenIntent()
            openAppIntent.appId = info.identifier
            openAppIntent.appName = defaultIntentAppName
            openAppIntent.suggestedInvocationPhrase = "Open %@.".localizedFormatted(defaultIntentAppName)
            return [openAppIntent]
        } else {
            return []
        }
    }

    static var defaultIntentAppName:String{
        if #available(iOS 12.0, *) {
            return NSString.deferredLocalizedIntentsString(with: info.displayName) as String
        }else{
            return "Undefined"
        }
    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }
}