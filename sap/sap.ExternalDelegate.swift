//
// Created by BLACKGENE on 2018-11-10.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

/// INFO:
/// An example of sub app case
/// if remove this swift file, automatically normal policy

extension AppColorTheme:AppColorDefaultThemeExternalDelegate{
    private(set) static var theme: AppColorTheme = .dark
}

extension AppDelegate: AppDelegateExternalDelegate{
    public func willFinishLaunching() {}


    public func didFinishLaunching() {
        //INFO: system wide free.
        if !AppCenter.charge.isPaid(payable: FreeAllAppsPayment.self){
            AppCenter.charge.pay(for: FreeAllAppsPayment.self, skipTransaction: true)
        }
    }
}

extension AppCenter:AppCenterExternalDelegate{
    static var defaultConfig: AppManagerConfig {
        return AppCenter.defaultConfigWholeUniversal

        /// Example: Support only artist app.
//        return AppManagerConfig(
//                appCollection: [ArtistApp.self]
//                , initialApp: nil
//                , taskManager: nil
//        )
    }
}
