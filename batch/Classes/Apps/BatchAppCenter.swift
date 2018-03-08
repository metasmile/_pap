//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public final class BatchAppCenter: AppManager, AppManagerConfigurable, KeyPathWatchable {
    public static let `default` = BatchAppCenter()

    func configure() -> [App.Type] {

        TransformApp.configure = {
            let config = TransformAppConfig()
            config.tintColor = .black
            return config
        }

        return [
            TransformApp.self
            , RevertApp.self
        ]
    }
}
