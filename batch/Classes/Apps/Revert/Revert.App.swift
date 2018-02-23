//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public class RevertApp: AppPrototype, Appable, FinalizableAppable {
    public static let taskType:Taskable.Type = _RevertAppTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<BatchAppPHAssetState>.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.revert"
            , version: "0.1"
            , state: .develop
            , appType: RevertApp.self
            , displayName: "Revert"
            , iconImage: "Revert.App.Icon"
            , lifeCycleUnit: .systemMemory
    )

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable] {
        return result
    }
}

private class _RevertAppTask: TaskPrototype, Taskable {
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param:TaskParamable, _ async: TaskAsyncSignalable?){
        (param as? PHAssetItem<Any>)?.cancelEditing()
    }

    public func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {

//        PHPhotoLibrary.shared().performChanges({
//            let request = PHAssetChangeRequest(for: self)
//            request.revertAssetContentToOriginal()
//        }, completionHandler: { success, error in
//            if !success { print("can't revert asset: \(String(describing: error))") }
//        })


        return nil
    }
}

