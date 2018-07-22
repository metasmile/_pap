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

            papLog.event.appSelected()
        }

        if let configuredAppIdentifier = Defaults.shared.appIdentifier
        , let starterApp = apps.first(where:{ appType in appType.info.identifier == configuredAppIdentifier }){
            self.current = starterApp

        }else{
            self.current = apps.first
        }
    }

    func configure() -> AppManagerConfig? {

        TransformApp.configure = {
            let config = TransformAppConfigValue()
            config.tintColor = UIColor(red:0.75, green:0.31, blue:0.8, alpha:1)
            return config
        }
        
        FiltersApp.configure = {
            let config = FiltersAppConfigValue()
            config.tintColor = .black
            return config
        }
        
        Stabilizer.configure = {
            let config = StabilizerAppConfigValue()
            config.tintColor = .black
            return config
        }
        
        GIFMakerApp.configure = {
            let config = GIFMakerAppConfigValue()
            config.tintColor = .black
            return config
        }

        var config = AppManagerConfig()
        //TODO: append/remove dynamically
        //TODO: Reorder via icon DnD
        //TODO: batchOS essential/settings app (it cannot be removed)

        let defaultAppCollection:[App.Type] = [
            MemoCamApp.self
            , FinderApp.self
            , TransformApp.self
            , FiltersApp.self
            , CameraApp.self
            , RevertApp.self
            , ConverterApp.self
            , GIFMakerApp.self
            , PhoneCallsApp.self
            , PDFactoryApp.self
            , AutoEditorApp.self
            , ExifGhostApp.self
            , CleanerApp.self
            , Stabilizer.self

        ].sorted { (appType1: App.Type, appType2: App.Type) -> Bool in

            return appType1.info.phase.rawValue > appType2.info.phase.rawValue
                    || papCount.app.countPerformed(app: appType1) > papCount.app.countPerformed(app: appType2)
        }

        config.appCollection = defaultAppCollection

        return config
    }
}
