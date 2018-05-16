//
// Created by BLACKGENE on 26/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
@testable import pap

public struct TestTaskParam:TaskParamable{
    var id:Int
}
public  struct TestTaskResult:TaskResultable{
    var id:Int
}

public class TestApp: App {
    public static let taskType:Taskable.Type = _TestAppTask.self

    public static let paramType:TaskParamable.Type = TestTaskParam.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.test"
            , version: "0.1"
            , phase: .develop
            , appType: TestApp.self
            , displayName: "TestApp"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )
    public required init() {}
}

private class _TestAppTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        async.begin()
        DispatchQueue.global().async{
            sleep(UInt32(arc4random_uniform(2)))
            async.end()
        }
        async.waitUntilEnd()
        return TestTaskResult(id:(param as! TestTaskParam).id)
    }
}