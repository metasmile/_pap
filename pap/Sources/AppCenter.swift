//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

extension AppCenter:AppManagerConfigurable{
    static func configure() -> AppManagerConfig? {

        let anySelf:Any.Type = self
        return (anySelf as? AppCenterExternalDelegate.Type)?.defaultConfig
    }
}

public final class AppCenter: AppManager, PropertyWatchable {
    public static let `default` = AppCenter()

    private override init() {
        super.init()

        let apps = self.apps(by: AppQuery.default)

        if apps.count == 0{
            return
        }
        assert(apps.first != nil,"\(apps) is wrongly defined check apps array.")

        self.watch(\.currentIdentifier) { (target, value) in
            Defaults.shared.appIdentifier = target.currentIdentifier
            print("Current App: \(Defaults.shared.appIdentifier ?? "nil")")

            papLog.appSelected()
        }

        if let configuredAppIdentifier = Defaults.shared.appIdentifier
        , let starterApp = apps.first(where:{ appType in appType.info.identifier == configuredAppIdentifier }){
            self.current = starterApp

        }else{
            self.current = config?.initialApp ?? apps.first
        }
    }
}
