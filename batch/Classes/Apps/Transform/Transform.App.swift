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

public struct TransformAppTaskRespondable:TaskResultable {
    var asset: PHAsset
    var contentEditingOutput: PHContentEditingOutput
}

public class TransformApp: AppPrototype, Appable, ParamableAppable, FinalizableAppable {
    //TODO: Result type

    public typealias ParamType = PHAssetItem
    public static let paramClass: ParamType.Type = ParamType.self

    public static let taskClass:Taskable.Type = _TransfromAppTask.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.transform"
            , appClass: TransformApp.self
            , displayName: "Transform"
            , iconImage: ImageSourceItem("batchappicon_transfrom.pdf")
    )

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable] {
        return result
    }
}

//TODO: retrictful conforms param type
private class _TransfromAppTask: TaskPrototype, Taskable {
    public typealias ParamType = PHAssetItem
    public typealias ResultType = TransformAppTaskRespondable

    public func cancel(_ param:TaskParamable, _ async: TaskAsyncSignalable?){
        
        (param as? PHAssetItem)?.cancelEditing()
    }

    public func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        assert(param is PHAssetItem, "TaskParamable type of this app is \(PHAssetItem.self)")
        guard let _param = param as? PHAssetItem else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ batchEditItem: PHAssetItem, _ async: TaskAsyncSignalable?) throws -> TransformAppTaskRespondable?  {
        var result: TransformAppTaskRespondable?

        async?.begin()

        batchEditItem.runEditing(nil) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = TransformAppTaskRespondable(
                        asset: asset,
                        contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }

        async?.stopUntilEnd()
        return result


    }
}
