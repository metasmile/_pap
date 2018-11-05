//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

public final class AppCenter: AppManager, AppManagerConfigurable, PropertyWatchable {
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

    func configure() -> AppManagerConfig? {

        var config = AppManagerConfig()

        let defaultAppCollection:[App.Type] = [
            TransformApp.self
            , FinderApp.self
            , FiltersApp.self
            , ConverterApp.self
            , ArtistApp.self
            , CleanerApp.self
            , GIFMakerApp.self
            , RevertApp.self
            , PDFactoryApp.self
            , CameraApp.self
            , ShopApp.self
            , AutoEditorApp.self
            , ExifGhostApp.self
            , SiriApp.self
            , ClipboardApp.self
//            , Stabilizer.self

        ].sorted { (appType1: App.Type, appType2: App.Type) -> Bool in

            if appType1.info.phase.rawValue > appType2.info.phase.rawValue{
                return true
            }

            if papCount.app.countPerformed(app: appType1) > papCount.app.countPerformed(app: appType2){
                return true
            }

            if appType1 is SApp.Type && appType2 is BApp.Type {
                return true
            }

            if appType1 is AVCaptureDeviceApp.Type == false && appType2 is AVCaptureDeviceApp.Type{
                return true
            }

            return false
        }

        config.appCollection = defaultAppCollection

        print("[i] App Internal Collection: ",defaultAppCollection)

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
