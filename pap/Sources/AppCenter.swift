//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

public final class AppCenter: AppManager, AppManagerConfigurable, KeyPathWatchable {
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

            papLog.appSelected()
        }

        if let configuredAppIdentifier = Defaults.shared.appIdentifier
        , let starterApp = apps.first(where:{ appType in appType.info.identifier == configuredAppIdentifier }){
            self.current = starterApp

        }else{
            self.current = apps.first
        }
    }

    func configure() -> AppManagerConfig? {

        var config = AppManagerConfig()

        let defaultAppCollection:[App.Type] = [
            MemoCamApp.self
            , FinderApp.self
            , TransformApp.self
            , FiltersApp.self
            , PhoneCallsApp.self
            , ConverterApp.self
            , CleanerApp.self
            , GIFMakerApp.self
            , RevertApp.self
            , PDFactoryApp.self
            , AutoEditorApp.self
            , ExifGhostApp.self
            , Stabilizer.self

            //SApp
            , CameraApp.self
            , ShopApp.self

        ].sorted { (appType1: App.Type, appType2: App.Type) -> Bool in

            return appType1.info.phase.rawValue > appType2.info.phase.rawValue
                    || papCount.app.countPerformed(app: appType1) > papCount.app.countPerformed(app: appType2)
                    || appType1 is BApp && appType2 is SApp
        }

        config.appCollection = defaultAppCollection

        #if DEBUG
        for app in defaultAppCollection{
            print(app.info.displayName)
            print(app.info.description ?? "")
//            print(app.info.keywords?.joined(separator: ",") ?? "")
        }
        #endif

        return config
    }
}
