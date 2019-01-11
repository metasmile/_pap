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
    func didLaunchHandling(with userActivity: NSUserActivity) {}
    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {}

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

    /*
        Full Customized macro
    */
    @available(iOS 12.0, *)
    static func intentTo(do what:String) -> DoAnyIntent{
        let doAnyTaskIntent = DoAnyIntent()
        doAnyTaskIntent.appId = info.identifier
        doAnyTaskIntent.doWhat = what
        doAnyTaskIntent.suggestedInvocationPhrase = doAnyTaskIntent.doWhat
        return doAnyTaskIntent
    }

    @available(iOS 12.0, *)
    static var intentToDoAutoSelection:AutoSelectIntent{
        let asb = AutoSelectIntent()
        asb.appId = info.identifier
        asb.appName = defaultIntentAppName
        asb.suggestedInvocationPhrase = "Auto Select on %@.".localizedFormatted(defaultIntentAppName)
        return asb
    }
}
