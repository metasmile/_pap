//
// Created by BLACKGENE on 14.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension AppLaunchOptionsKey {
    //value type: App.Type
    static var SourceAppType:AppLaunchOptionsKey { return autoKey() }

    //value type: UserActivity
    static var NSUserActivity:AppLaunchOptionsKey { return autoKey() }

    //value type: UserActivity
    static var UIApplicationShortcutItem:AppLaunchOptionsKey { return autoKey() }

    //value type: PHAsset
    static var PHAsset:AppLaunchOptionsKey { return autoKey() }

    //value type: URL
    static var PhotoURL:AppLaunchOptionsKey { return autoKey() }

    //value type: URL
    static var PairedVideoURL:AppLaunchOptionsKey { return autoKey() }
}