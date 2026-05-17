//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension AppColorTheme:AppColorDefaultThemeExternalDelegate{
    private(set) static var theme: AppColorTheme = .dark
}

extension AppDelegate: AppDelegateExternalDelegate{
    public func willFinishLaunching() {
    }

    public func didFinishLaunching() {

    }
}

extension AppCenter:AppCenterExternalDelegate{
    static var defaultConfig: AppManagerConfig {
        return AppCenter.defaultConfigWholeUniversal
    }
}