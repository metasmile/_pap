//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

private typealias RevertAppParam = PHAssetItem<BatchAppPHAssetState>

public class RevertApp: NSObject, KeyPathWatchable, App, FinalizableApp {
    public static let taskType:Taskable.Type = _RevertAppTask.self

    public static let paramType:TaskParamable.Type = RevertAppParam.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.revert"
            , version: "0.1"
            , state: .beta
            , appType: RevertApp.self
            , displayName: "Revert"
            , icon: "Revert.App.Icon"
            , policy: AppPolicy.default
    )

    required public override init(){
        super.init()
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable] {
        if result.isAnyTask(inState: .cancelled) && result.defaultTaskPolicy.cancellation == TaskPolicy.Cancellation.shallow {
            return result
        }

        let resultAssets = result.flatMap { ($0.result as? PHAssetResultable)?.asset }

        guard resultAssets.count > 0 else {
            return result
        }

        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            for asset in resultAssets{
                PHAssetChangeRequest(for: asset).revertAssetContentToOriginal()
            }
        }, completionHandler: { success, error in
            if !success {
                print("[!] Can't revert asset: \(String(describing: error))")
            }

            asyncSignal.end()
        })

        asyncSignal.stopUntilEnd()
        return result
    }
}

private class _RevertAppTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: TaskAsyncSignalable?){}

    public func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        assert(param is RevertAppParam, "TaskParamable type of this app is \(RevertAppParam.self)")

        guard let _param = param as? RevertAppParam else{
            throw TaskError.invalidParam
        }

        var adjusted = false

        async?.begin()
        _param.asset.fetchAdjustmentData { data in
            adjusted = data != nil
            async?.end()
        }

        async?.stopUntilEnd()

        if adjusted{
            return PHAssetResultItem(asset:_param.asset, contentEditingOutput: nil)
        }

        throw TaskError.rejectedParam
    }
}

