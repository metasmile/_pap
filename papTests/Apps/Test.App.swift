//
// Created by BLACKGENE on 26/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
@testable import pap

public struct TestTaskParam: AppTaskParamable {
    var id:Int
}
public  struct TestTaskResult: AppTaskResultable {
    var id:Int
}

public class TestApp: App {
    public static let taskType: AppTaskable.Type = _TestAppTask.self

    public static let paramType: AppTaskParamable.Type = TestTaskParam.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.test"
            , version: "0.1"
            , phase: .develop
            , appType: TestApp.self
            , displayName: "TestApp", description:nil, keywords:nil
            , iconBundleName: nil
            , themeColor: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )
    public required init() {}
}

private class _TestAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        async.begin()
        DispatchQueue.global().async{
            sleep(UInt32(arc4random_uniform(2)))
            async.end()
        }
        async.waitUntilEnd()
        return TestTaskResult(id:(param as! TestTaskParam).id)
    }
}

