//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

// Location
// Date
// ... Option to remove
// All

public class ExifGhost: App {
    public static let taskType:Taskable.Type = _ExifGhostTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<AppValue>.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.exifghost"
            , version: "0.1"
            , phase: .develop
            , appType: ExifGhost.self
            , displayName: "EXIF Ghost"
            , icon: nil
            , policy: AppPolicy.default
    )

    public required init() {}
}


private class _ExifGhostTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        throw TaskError.internalException
    }
}

