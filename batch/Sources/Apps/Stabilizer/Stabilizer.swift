//
// Created by BLACKGENE on 11/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public class Stabilizer: App, PersistableApp, PHAssetFinalizableApp, AppDockControllableApp, PhotoPickerViewControllerDelegatableApp {
    public static let taskType:Taskable.Type = StabilizerTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<AppValue>.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.stabilizer"
            , version: "0.1"
            , phase: .develop
            , appType: Stabilizer.self
            , displayName: "Stabilizer"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public required init() {}

    public var finalizingOptions: [PHAssetFinalizingOption]{
        return [.delete]
    }

    public var titleWillFinalize: String? {
        return "Stabilizing Selected Items...".localized
    }
    public var doneButtonTitle: String? {
        return "Stabilize".localized
    }
}

private class StabilizerTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        if let asset = (param as? PHAssetItem<AppValue>)?.asset{
            return PHAssetResultItem(asset: asset, contentEditingOutput: nil)
        }
        return nil
    }
}

