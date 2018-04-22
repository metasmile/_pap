//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

public final class AppCenter: AppManager, AppManagerConfigurable, KeyPathWatchable {
    public static let `default` = AppCenter() //FIXME CRITICAL:  when call AppCenter.default in every each App.init() -> EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0)

    override init() {
        super.init()

        let apps = self.apps(by: AppQuery.default)

        if let configuredAppIdentifier = Defaults.shared.appIdentifier{
            self.current = apps.first { appType in appType.info.identifier == configuredAppIdentifier }
        }else{
            Defaults.shared.appIdentifier = self.currentIdentifier
        }

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
        
        PhotosFilterApp.configure = {
            let config = PhotosFilterAppConfig()
            config.tintColor = .black
            return config
        }
        
        Stabilizer.configure = {
            let config = StabilizerAppConfig()
            config.tintColor = .black
            return config
        }

        var config = AppManagerConfig()
        config.appCollection = [
            TransformApp.self
            , PhotosFilterApp.self
            , RevertApp.self
            , PDFactory.self
            , ExifGhost.self
            , Clean.self
            , Stabilizer.self
            , AutoAdjustmentApp.self
        ]

        return config
    }
}
