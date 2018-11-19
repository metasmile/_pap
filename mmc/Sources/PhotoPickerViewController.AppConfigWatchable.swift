//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension PhotoPickerViewController:AppDockViewControllerAppConfigWatchableDelegate{

    func registerWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(FinderApp.self)?.watch(\.autoSelect, id: "picker\(FinderApp.info.identifier)") { (app, changed) in
            if app.autoSelect && !AppCenter.default.task.isRunning {
                self.cancelPreheatingIfNeeded()
                self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
            }
        }
    }

    func unregisterWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(FinderApp.self)?.unwatch(\.autoSelect, forIds:["picker\(FinderApp.info.identifier)"])
        AppCenter.default.unwatchAllFilePrivate(\.currentIdentifier)
    }

}