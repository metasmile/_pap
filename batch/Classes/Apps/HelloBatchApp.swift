//
// Created by BLACKGENE on 26/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Dispatch
import UIKit

//TODO: more strictful parameter type for public
struct HelloTaskParameter: TaskParameterable{
    var sources:[Sourceable]?
    var configs:[TaskConfigable]?
}

struct HelloTaskResult: TaskResultable{
    var results:[Sourceable]?
}

//HELLO: This app "HelloBatchApp" is supporting "FinalizableApp" for example PHAsset handling.
public class HelloBatchApp: AppPrototype, App, FinalizableApp  {
    public static var info: AppInfo {
        get{
            let info = AppInfo("com.stells.batch.hello", self)
            info.displayName = "Hello Batch"
            info.iconImage = ImageSourceItem("batch_app_icon.pdf")
            return info
        }
    }

    //HELLO: In the near future, multiple Task will be supported.
    public var taskClass: Task.Type {
        return HelloTask.self
    }

    public func finalizeTasks(_ response: AppTaskResult, _ asyncSignal: TaskAsyncSignalable) -> AppTaskResult {

        return response
    }
}

//HELLO: HelloTask - Default Task
private class HelloTask: TaskPrototype, TypedTask{
    typealias ParamType = HelloTaskParameter
    typealias ResultType = HelloTaskResult

    var property:String?

    public func cancel(_ async: TaskAsyncSignalable?){

    }

    func perform(_ param: ParamType, _ async: TaskAsyncSignalable?) throws -> ResultType?  {
        return nil
    }
}

//HELLO: "HelloTask-specific" task implementation
private extension TypedTask
        where Self== HelloTask, Self.ParamType == HelloTaskParameter, Self.ResultType == HelloTaskResult {

    func perform(_ param: HelloTaskParameter, _ async: TaskAsyncSignalable?) throws -> HelloTaskResult?  {

        //HELLO: can access property. using "where Self== HelloTask"
        let prop = self.property

        return nil
    }
}

//HELLO: more general perform implementation apart from specific task type
private extension TypedTask
        where ParamType == HelloTaskParameter, ResultType == HelloTaskResult {

    func perform(_ param: HelloTaskParameter, _ async: TaskAsyncSignalable?) throws -> HelloTaskResult?  {

        return nil
    }
}

//HELLO: HelloAsyncTask - Async Task
private class HelloAsyncTask: TaskPrototype, TypedTask{
    typealias ParamType = HelloTaskParameter
    typealias ResultType = HelloTaskResult

    public func cancel(_ async: TaskAsyncSignalable?){
        //HELLO: same as "perform", all the cancellation processes are also affected by this.
    }

    func perform(_ param: ParamType, _ async: TaskAsyncSignalable?) throws -> ResultType?  {
        var helloResult:ResultType? = nil

        //HELLO: use begin() if this task internally need async code.
        async?.begin()

        DispatchQueue.global().async {
            if let image = param.sources?.first as? ImageSourceable{
                //HELLO: process an image ... or fetch some remote resources from AFNetworking for example
                image.asImage

                helloResult = HelloTaskResult(results: [UIImage()])

                //HELLO: async process is finished.
                async?.end()
            }
        }

        //HELLO: next tasks in same queue for each apps are waiting until below processes are finished.
        async?.stopUntilEnd()

        //HELLO: if "async?.end()" is called, and then sync return -> next task will start
        return helloResult
    }
}