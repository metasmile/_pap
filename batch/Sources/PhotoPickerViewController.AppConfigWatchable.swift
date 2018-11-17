//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension PhotoPickerViewController:AppDockViewControllerAppConfigWatchableDelegate{

    func registerWatchingAppConfig() {
        AppCenter.default.watch(\.currentIdentifier, options: [.new, .old, .initial]) { (appCenter, dict) in

            AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id: "picker\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform, !AppCenter.default.task.isRunning {
                    self.appendImageEditState(value)
                }
            }

            AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.watch(\.filter, id: "picker\(FiltersApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.task.isRunning {
                    self.appendImageEditState(value)
                }
            }

            AppCenter.default.currentInstanceAs(ArtistApp.self)?.config?.watch(\.filter, id: "picker\(ArtistApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.task.isRunning {
                    self.appendImageEditState(value)
                }
            }

            AppCenter.default.currentInstanceAs(AutoEditorApp.self)?.config?.watch(\.filter, id: "picker\(AutoEditorApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.task.isRunning {
                    self.appendImageEditState(value)
                }
            }

            AppCenter.default.currentInstanceAs(StabilizerApp.self)?.config?.watch(\.stabilizationMode, id: "picker\(StabilizerApp.info.identifier)") { (config, changed) in
                if let value = config.stabilizationMode, !AppCenter.default.task.isRunning {
                    self.appendImageEditState(value)
                }
            }

            AppCenter.default.currentInstanceAs(GIFMakerApp.self)?.config?.watch(\.sourceType, id: "picker\(GIFMakerApp.info.identifier)") { (config, changed) in
                self.redisplayVisibleCells()
            }

            AppCenter.default.currentInstanceAs(ConverterApp.self)?.config?.watch(\.convertingDirectionIdentifier, id: "picker\(ConverterApp.info.identifier)") { (config, changed) in
                self.redisplayVisibleCells()
            }

            //TODO: make a group for preheatable apps
            AppCenter.default.currentInstanceAs(RevertApp.self)?.watch(\.autoSelect, id: "picker\(RevertApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }

            AppCenter.default.currentInstanceAs(ExifGhostApp.self)?.watch(\.autoSelect, id: "picker\(ExifGhostApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }


            AppCenter.default.currentInstanceAs(CleanerApp.self)?.watch(\.autoSelect, id: "picker\(CleanerApp.info.identifier)") { (app, changed) in
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }

            AppCenter.default.currentInstanceAs(ConverterApp.self)?.watch(\.autoSelect, id: "picker\(ConverterApp.info.identifier)") { (app, changed) in
                print( app.autoSelect)
                if app.autoSelect && !AppCenter.default.task.isRunning {
                    self.cancelPreheatingIfNeeded()
                    self.performPrefetchIfNeeded(includingCurrentVisibleItems: true)
                }
            }

            AppCenter.default.currentInstanceAs(ResizerApp.self)?.config?.watch(\.filter, id: "picker\(ResizerApp.info.identifier)") { (config, changed) in
                if let value = config.filter, !AppCenter.default.task.isRunning {
                    self.appendImageEditState(value)
                }
            }

            AppCenter.default.currentInstanceAs(ConfigurableApp.self)?.setConfigValues(AppConfigUIAttribute(tintColor: self.view.colorTheme.textColor))
        }
    }

    func unregisterWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["picker\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.unwatch(\.filter, forIds:["picker\(FiltersApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ArtistApp.self)?.config?.unwatch(\.filter, forIds:["picker\(ArtistApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(AutoEditorApp.self)?.config?.unwatch(\.filter, forIds:["picker\(AutoEditorApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(StabilizerApp.self)?.config?.unwatch(\.stabilizationMode, forIds:["picker\(StabilizerApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(GIFMakerApp.self)?.config?.unwatch(\.sourceType, forIds:["picker\(GIFMakerApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ConverterApp.self)?.config?.unwatch(\.convertingDirectionIdentifier, forIds:["picker\(ConverterApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(RevertApp.self)?.unwatch(\.autoSelect, forIds:["picker\(RevertApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ExifGhostApp.self)?.unwatch(\.autoSelect, forIds:["picker\(ExifGhostApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(CleanerApp.self)?.unwatch(\.autoSelect, forIds:["picker\(CleanerApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ResizerApp.self)?.config?.unwatch(\.filter, forIds:["picker\(ResizerApp.info.identifier)"])

        AppCenter.default.unwatchAllFilePrivate(\.currentIdentifier)
    }

}