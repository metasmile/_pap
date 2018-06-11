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

        TransformApp.configure = {
            let config = TransformAppConfigValue()
            config.tintColor = .black
            return config
        }
        
        PhotosFilterApp.configure = {
            let config = PhotosFilterAppConfigValue()
            config.tintColor = .black
            return config
        }
        
        Stabilizer.configure = {
            let config = StabilizerAppConfigValue()
            config.tintColor = .black
            return config
        }
        
        GIFMaker.configure = {
            let config = GIFMakerAppConfigValue()
            config.tintColor = .black
            return config
        }

        var config = AppManagerConfig()
        //TODO: append/remove dynamically
        //TODO: Reorder via icon DnD
        //TODO: batchOS essential/settings app (it cannot be removed)

        config.appCollection = [
            TransformApp.self
            , PhotosFilterApp.self
            , RevertApp.self
            , ConvertApp.self
            , GIFMaker.self
            , PDFactory.self
            , AutoAdjustmentApp.self
            , ExifGhost.self

//            , Clean.self
            , Stabilizer.self
        ]

        return config
    }
}
