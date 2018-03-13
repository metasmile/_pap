//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public final class AppCenter: AppManager, AppManagerConfigurable, KeyPathWatchable {
    public static let `default` = AppCenter()

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
        ]

        return config

    }
}
