//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public class Clean: BApp, PHAssetFinalizableApp, AppDockControllableApp, PhotoPickerViewControllerDelegatableApp {
    public static let taskType:Taskable.Type = _CleanTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.clean"
            , version: "0.1"
            , phase: .develop
            , appType: Clean.self
            , displayName: "Clean"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public required init() {}

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.delete]
    }

    public var titleWillFinalize: String? {
        return "Deleting Photos...".localized
    }
    public var doneButtonTitle: String? {
        return "Delete".localized
    }
}

private class _CleanTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        if let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset{
            return PHAssetResultItem(asset: asset, contentEditingOutput: nil)
        }
        return nil
    }
}

