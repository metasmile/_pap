//
// Created by BLACKGENE on 2018-10-03.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Intents

//INFO: Should call with directly related functions.
protocol UIApplicationDelegateLaunchableApp: App {
    static var intents:[INIntent] {get}

    //INFO: instance function are meaning that all required pre-processes are finished and current app has existed as an instance.
    func didLaunchHandling(with userActivity:NSUserActivity)

    func didLaunchHandling(with shortcutItem:UIApplicationShortcutItem)
}

extension INIntent {
    //INFO: All custom intent should define "appId" property by its own.
    static let kAppIdentifier = "appId"

    var appIdentifier:String?{
        return value(forKey: INIntent.kAppIdentifier) as? String
    }
}
