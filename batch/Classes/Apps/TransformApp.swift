//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import QuartzCore
import Photos
import UIKit
import MobileCoreServices


public struct TransformAppTaskResult:TaskResultable {
    var asset: PHAsset
//    var indexPath:IndexPath?
    var contentEditingOutput: PHContentEditingOutput
}

public class TransformApp: AppPrototype, Appable, ParamableAppable, FinalizableAppable {
    //TODO: Result type

    public typealias ParamType = TransformAppEditItem
    public static let paramClass: ParamType.Type = ParamType.self

    public static let taskClass:Taskable.Type = _TransfromTask.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.transform"
            , appClass: TransformApp.self
            , displayName: "TransformApp"
            , iconImage: ImageSourceItem("batchappicon_transfrom.pdf")
    )

    public func finalize(result: AppTaskResult, _ asyncSignal: TaskAsyncSignalable) -> AppTaskResult {
        return result
    }
}

private class _TransfromTask: TaskPrototype, TypedTaskable {
    public typealias ParamType = TransformAppEditItem
    public typealias ResultType = TransformAppTaskResult

    weak var item:TransformAppEditItem?

    public func cancel(_ async: TaskAsyncSignalable?){
        item?.cancelEditing()
    }

    func perform(_ batchEditItem: TransformAppEditItem, _ async: TaskAsyncSignalable?) throws -> TransformAppTaskResult?  {
        print("start",batchEditItem)
        item = batchEditItem

        async?.begin()

        var result: TransformAppTaskResult?

        batchEditItem.runEditing(nil) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = TransformAppTaskResult(
                        asset: asset,
//                        indexPath: self.item?.indexPath,
                        contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }

        async?.stopUntilEnd()

        print("end",batchEditItem)
        return result


    }
}
