//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import QuartzCore
import Photos
import UIKit
import MobileCoreServices
import Crashlytics

class _TransformAppAsset: PHAssetItem<BatchAppPHAssetState> {}

public class TransformApp: AppPrototype, Appable, FinalizableAppable {
    public static let taskType:Taskable.Type = _TransfromAppTask.self

    public static let paramType:TaskParamable.Type = _TransformAppAsset.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.transform"
            , version: "1.0"
            , state: .release
            , appType: TransformApp.self
            , displayName: "Transform"
            , iconImage: "Transform.App.Icon"
            , lifeCycleUnit: .systemMemory
    )

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable] {
        return result
    }
}

//TODO: retrictful conforms param type
private class _TransfromAppTask: TaskPrototype, Taskable {

    public typealias ParamType = _TransformAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param:TaskParamable, _ async: TaskAsyncSignalable?){

        (param as? _TransformAppAsset)?.cancelEditing()
    }

    public func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        assert(param is _TransformAppAsset, "TaskParamable type of this app is \(_TransformAppAsset.self)")
        guard let _param = param as? _TransformAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _TransformAppAsset, _ async: TaskAsyncSignalable?) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?

        async?.begin()

        assetItem.runEditing(nil) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                        asset: asset,
                        contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }

        async?.stopUntilEnd()
        return result


    }
}
