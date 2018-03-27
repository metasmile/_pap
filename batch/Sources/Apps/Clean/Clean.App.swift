//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public class Clean: App, PersistableApp, PHAssetFinalizableApp, UIControllableApp {
    public static let taskType:Taskable.Type = _CleanTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<AppValue>.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.clean"
            , version: "0.1"
            , phase: .develop
            , appType: Clean.self
            , displayName: "Clean"
            , icon: nil
            , policy: AppPolicy.default
    )

    public required init() {}

    public var finalizingOptions: PHAssetFinalizingOptions{
        return [.delete]
    }
}

private class _CleanTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        if let asset = (param as? PHAssetItem<AppValue>)?.asset{
            return PHAssetResultItem(asset: asset, contentEditingOutput: nil)
        }
        return nil
    }
}

