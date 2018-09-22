//
//  AppDelegate.Intents.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 9. 14..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Intents

class IntentsAppDelegate: NSObject, UIApplicationDelegate {

    @discardableResult
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if let activityDictionary = launchOptions?[UIApplicationLaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] { //Universal link

            for key in activityDictionary.keys {
                if let userActivity = activityDictionary[key] as? NSUserActivity {
                    self.application(application, continue: userActivity, restorationHandler: { _ in })
                    break
                }
            }
        }

        return true
    }

    @discardableResult
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if #available(iOS 12.0, *) {
            guard let intent = userActivity.interaction?.intent, let appId = intent.appIdentifier else {
                return false
            }

            userActivity.isEligibleForSearch = true
            userActivity.isEligibleForPrediction = true

            if IntentsAppDelegate.launchAppIfNeededWithAppId(appId, userActivity: userActivity){
                UIFeedback.notify(.success)
            }else{
                UIFeedback.impact(.heavy)
            }
        }
        return true
    }
}

extension IntentsAppDelegate {
    @discardableResult
    public static func launchAppIfNeededWithAppId(_ appId: String?, userActivity:NSUserActivity) -> Bool {
        guard let appId = appId else {
            return false
        }

        return AppCenter.default.openApp(identifier: appId, options: AppLaunchOptions(options: [.NSUserActivity: userActivity])) { hasChanged in
            AppCenter.default.currentInstanceAs(UIApplicationDelegatableApp.self)?.didFinishLaunchHandlingWith(userActivity:userActivity)
        }
    }
}
