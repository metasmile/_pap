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

    public var taskClass: Task.Type {
        return _TransfromTask<TransformAppParam>.self
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


extension EditItem: TaskConfigable{

}

public struct TransformAppParam: TaskParameterable{
    public var sources:[Sourceable]?
    public var configs:[TaskConfigable]?
}

protocol TypedTask: Task{
    associatedtype Parameter_T
    associatedtype Return_T
    func perform<Parameter_T:TaskParameterable>(_ param:Parameter_T, _ async: TaskAsyncSignalable?) throws -> Return_T?
}

extension TypedTask{
    public func perform(_ param: TaskParameterable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        return try self.perform(param, async)
    }
}

extension TypedTask where Parameter_T == TransformAppParam{
    func perform(_ param: TransformAppParam, _ async: TaskAsyncSignalable?) throws -> TaskResultable?  {

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

private class _TransfromTask<T>: TaskPrototype, TypedTask {
    typealias Parameter_T = T

    public func cancel(_ async: TaskAsyncSignalable?){
        print("--->", #function, type(of:self), self.info.requestToken)
    }

    func perform<Parameter_T>(_ param:Parameter_T, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        return nil
    }
}
