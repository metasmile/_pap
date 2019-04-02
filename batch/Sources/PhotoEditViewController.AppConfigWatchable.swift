//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension PhotoEditViewController:AppDockViewControllerAppConfigWatchableDelegate{

    func registerWatchingAppConfig() {
        AppCenter.default.watch(\.currentIdentifier, id:"editor", options:[.new, .initial]) { appCenter, dict in

            appCenter.currentInstanceAs(TransformApp.self)?.config?.watch(\.transform, id:"editor\(TransformApp.info.identifier)") { (config, changed) in
                if let value = config.transform{
                    self.appendImageEditState(value)
                }
            }

            appCenter.currentInstanceAs(FiltersApp.self)?.config?.watch(\.filter, id:"editor\(FiltersApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }

            appCenter.currentInstanceAs(ArtistApp.self)?.config?.watch(\.filter, id:"editor\(ArtistApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }

            appCenter.currentInstanceAs(AutoEditorApp.self)?.config?.watch(\.filter, id:"editor\(AutoEditorApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }

            appCenter.currentInstanceAs(StabilizerApp.self)?.config?.watch(\.stabilizationMode, id:"editor\(StabilizerApp.info.identifier)") { (config, changed) in
                if let value = config.stabilizationMode {
                    self.appendImageEditState(value)
                }
            }

            appCenter.currentInstanceAs(ResizerApp.self)?.config?.watch(\.filter, id:"editor\(ResizerApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }
            
            appCenter.currentInstanceAs(AdjustmentsApp.self)?.config?.watch(\.filter, id:"editor\(AdjustmentsApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }

            appCenter.currentInstanceAs(DepthEditorApp.self)?.config?.watch(\.filter, id:"editor\(DepthEditorApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }
            
            appCenter.currentInstanceAs(RawEditorApp.self)?.config?.watch(\.filter, id:"editor\(RawEditorApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }
            
            appCenter.currentInstanceAs(ColorEditorApp.self)?.config?.watch(\.filter, id:"editor\(ColorEditorApp.info.identifier)") { (config, changed) in
                if let value = config.filter {
                    self.appendImageEditState(value)
                }
            }
            
            appCenter.currentInstanceAs(MergerApp.self)?.config?.watch(\.timeRange, id:"editor\(MergerApp.info.identifier)") { (config, changed) in
                if let value = config.timeRange {
                    self.appendImageEditState(value)
                }
            }

            //common ui attributes if current app is ConfigurableApp
            appCenter.currentInstanceAs(ConfigurableApp.self)?.setConfigValues(AppConfigUIAttribute(tintColor: self.view.colorTheme.textColor))
        }
    }

    func unregisterWatchingAppConfig() {
        AppCenter.default.currentInstanceAs(TransformApp.self)?.config?.unwatch(\.transform, forIds:["editor\(TransformApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.unwatch(\.filter, forIds:["editor\(FiltersApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ArtistApp.self)?.config?.unwatch(\.filter, forIds:["editor\(ArtistApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(AutoEditorApp.self)?.config?.unwatch(\.filter, forIds:["editor\(AutoEditorApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(StabilizerApp.self)?.config?.unwatch(\.stabilizationMode, forIds:["editor\(StabilizerApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ResizerApp.self)?.config?.unwatch(\.filter, forIds:["editor\(ResizerApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(AdjustmentsApp.self)?.config?.unwatch(\.filter, forIds:["editor\(AdjustmentsApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(DepthEditorApp.self)?.config?.unwatch(\.filter, forIds:["editor\(DepthEditorApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(RawEditorApp.self)?.config?.unwatch(\.filter, forIds:["editor\(RawEditorApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(ColorEditorApp.self)?.config?.unwatch(\.filter, forIds:["editor\(ColorEditorApp.info.identifier)"])
        AppCenter.default.currentInstanceAs(MergerApp.self)?.config?.unwatch(\.timeRange, forIds:["editor\(MergerApp.info.identifier)"])
        AppCenter.default.unwatch(\.currentIdentifier, forIds:["editor"])
    }
}
