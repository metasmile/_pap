//
// Created by BLACKGENE on 2018-11-10.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Armchair

//INFO: if remove this swift file, automatically normal policy

extension AppDelegate: AppDelegateExternalDelegate{
    public func willFinishLaunching() {}


    public func didFinishLaunching() {

        Armchair.appID(InfoStrings.appStoreId)
        Armchair.useStoreKitReviewPrompt( true)

    }
}

extension AppCenter:AppCenterExternalDelegate{
    static var defaultConfig: AppManagerConfig {
        return AppManagerConfig(
                appCollection: [SiriApp.self, FinderApp.self, MMCMemoCamApp.self]
                , initialApp: nil
                , taskManager: nil
        )
    }
}

extension InfoStrings:InfoStringsExternalDelegate{
    static var defaultTitle: String{
        return "Get Every Info Around You.".localized
    }

    static var defaultTagline: String{
        return "Get Text And Then Do Something.".localized
    }
}

extension AppColorTheme:AppColorDefaultThemeExternalDelegate{
    private(set) static var theme: AppColorTheme = .dark
}
