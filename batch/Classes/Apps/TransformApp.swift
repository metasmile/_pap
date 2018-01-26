//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import QuartzCore


public class TransformApp: AppPrototype, App, FinalizableApp  {

    public static var info: AppInfo {
        get{
            let info = AppInfo("com.stells.batch.transform", self)
            info.displayName = "Transform"
            info.iconImage = ImageSourceItem("batchappicon_transfrom.pdf")
            return info
        }
    }

    public static var taskClass: Task.Type {
        return _TransfromTask.self
    }

    public func finalizeTasks(_ response: AppTaskResult, _ asyncSignal: TaskAsyncSignalable) -> AppTaskResult {
//        asyncSignal.begin()

        print("------------->"
                , #function
                , type(of:self)
                , response.results.map{ ($0.info.requestToken, $0.info.token, $0.info.state) }
        )

        print("Result Status ---> total: ", response.results.count)
        let statuses:[TaskState] = [
            .unqueued
            ,.idling
            ,.performing
            ,.cancelled
            ,.failed
            ,.completed
        ]

        for var s in statuses{
            print(s, response.results.filter{ $0.info.state==s }.count)
        }

//        asyncSignal.end()
//        asyncSignal.stopUntilEnd()

        return response
    }
}

public struct TransformAppParam: TaskParam {
    public var sources:[Sourceable]?
    public var configs:[TaskConfigable]?
}


private class _TransfromTask: TaskPrototype, TypedTask{
    typealias ParamType = TransformAppParam
    typealias ResultType = TaskResultable

    var aaa:String?

    public func cancel(_ async: TaskAsyncSignalable?){
        print("--->", #function, type(of:self), self.info.requestToken)
    }

    func perform(_ param: TransformAppParam, _ async: TaskAsyncSignalable?) throws -> TaskResultable?  {

        let str = self.aaa

        async?.begin()
        param.configs

        let c = CACurrentMediaTime()
        DispatchQueue.global().async {
            sleep(UInt32(arc4random_uniform(2)))
            print("--->", #function, type(of:self), self.info.requestToken, CACurrentMediaTime()-c)
            async?.end()
        }

        async?.stopUntilEnd()

        return nil
    }
}
