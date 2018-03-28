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

        if let configuredAppIdentifier = Defaults.shared.appIdentifier{
            self.current = apps.first { appType in appType.info.identifier == configuredAppIdentifier }
        }

        if self.current == nil && apps.count==1 {
            self.current = apps.first
        }

        Defaults.shared.appIdentifier = self.currentIdentifier
        self.watch(\.currentIdentifier) { (target, value) in
            Defaults.shared.appIdentifier = target.currentIdentifier
        }
    }

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
            , Clean.self
            , PDFactory.self
            , PhotosFilterApp.self
        ]

        return config
    }
}
