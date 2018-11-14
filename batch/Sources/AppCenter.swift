//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

public final class AppCenter: AppManager, PropertyWatchable {
    public static let `default` = AppCenter()

    override init() {
        super.init()

        let apps = self.apps(by: AppQuery.default)

        if apps.count == 0{
            return
        }

        self.watch(\.currentIdentifier) { (target, value) in
            Defaults.shared.appIdentifier = target.currentIdentifier
            print("Current App: \(Defaults.shared.appIdentifier ?? "nil")")

            batchLog.appSelected()
        }

        if let configuredAppIdentifier = Defaults.shared.appIdentifier
        , let starterApp = apps.first(where:{ appType in appType.info.identifier == configuredAppIdentifier }){
            self.current = starterApp

        }else{
            self.current = initialApp
        }
    }

    private var initialApp:App.Type{
        return TransformApp.self
    }
}
