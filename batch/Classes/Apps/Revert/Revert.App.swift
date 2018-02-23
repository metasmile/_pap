//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


public class RevertApp: AppPrototype, Appable, FinalizableAppable {
    public static let taskClass:Taskable.Type = _RevertAppTask.self

    public static let paramClass:TaskParamable.Type = PHAssetItem<BatchAppPHAssetState>.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.revert"
            , version: "0.1"
            , state: .develop
            , appClass: RevertApp.self
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
        return nil
    }
}

