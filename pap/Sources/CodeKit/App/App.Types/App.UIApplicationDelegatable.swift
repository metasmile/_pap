//
// Created by BLACKGENE on 2018-09-22.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Intents

//INFO: Should call with directly related functions.

protocol UIApplicationDelegatableApp: App {
    static var intents:[INIntent] {get}

    //INFO: instance function are meaning that all required pre-processes are finished and current app has existed as an instance.
    func didFinishLaunchHandlingWith(userActivity:NSUserActivity)

    func didFinishLaunchHandlingWith(shortcutItem:UIApplicationShortcutItem)
}

extension INIntent {
    //INFO: All custom intent should define "appId" property by its own.
    static let kAppIdentifier = "appId"

    var appIdentifier:String?{
        return value(forKey: INIntent.kAppIdentifier) as? String
    }
}
