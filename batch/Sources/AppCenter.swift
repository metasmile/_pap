//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

public final class AppCenter: AppManager, AppManagerConfigurable, KeyPathWatchable {
    public static let `default` = { () -> AppCenter in
        let appCenter = AppCenter()

        if let configuredAppIdentifier = Defaults.shared.appIdentifier{
            appCenter.current = appCenter.app(by: AppInfoKey(identifier: configuredAppIdentifier))
        }

        appCenter.watch(\.currentIdentifier) { (target, value) in
            Defaults.shared.appIdentifier = target.currentIdentifier
        }
        
        return appCenter
    }()

    func configure() -> AppManagerConfig? {

        TransformApp.configure = {
            let config = TransformAppConfig()
            config.tintColor = .black
            return config
        }

        var config = AppManagerConfig()
        config.appCollection = [
            TransformApp.self
            , RevertApp.self
            , ExifGhost.self
            , Dieter.self
        ]

        return config
    }
}
