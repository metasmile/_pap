//
// Created by BLACKGENE on 2018-11-10.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//INFO: if remove this swift file, automatically normal policy

extension AppDelegate: AppDelegateExternalDelegate{
    public func willFinishLaunching() {}


    public func didFinishLaunching() {

    }
}

extension AppCenter:AppCenterExternalDelegate{
    static var defaultConfig: AppManagerConfig {
        return AppManagerConfig(
                appCollection: [SiriApp.self, FinderApp.self, MemoCamApp.self]
                , initialApp: nil
                , taskManager: nil
        )
    }
}