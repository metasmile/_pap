//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

private typealias RevertAppAsset = PHAssetItem<BatchAppPHAssetState>

extension Bool: TaskResultable{}

public class RevertApp: AppPrototype, Appable, FinalizableAppable {
    public static let taskType:Taskable.Type = _RevertAppTask.self

    public static let paramType:TaskParamable.Type = RevertAppAsset.self

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

    }

    public func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        assert(param is RevertAppAsset.Type, "TaskParamable type of this app is \(_TransformAppAsset.self)")
        guard let _param = param as? RevertAppAsset else{
            throw TaskError.invalidParam
        }

        var reverted = false
        async?.begin()

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: _param.asset)
            request.revertAssetContentToOriginal()

        }, completionHandler: { success, error in
            reverted = success

            if !success {
                print("can't revert asset: \(String(describing: error))")
            }

            async?.end()
        })

        async?.stopUntilEnd()

        if !reverted{
            throw TaskError.invalidResult
        }

        return reverted
    }
}

