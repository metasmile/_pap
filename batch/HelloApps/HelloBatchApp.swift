//
// Created by BLACKGENE on 26/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Dispatch
import UIKit

//TODO: more strictful parameter type for public
public struct HelloTaskParameter: TaskParam {
    public var sources:[Sourceable]?
    public var configs:[TaskConfigable]?
}

public struct HelloTaskResult: TaskResultable{
    public var results:[Sourceable]?
}

public protocol HelloTaskParam: TaskParam{

}

//HELLO: This app "HelloBatchApp" is supporting "FinalizableApp" for example PHAsset handling.
public class HelloBatchApp: AppPrototype, App, FinalizableApp {

    public static var info: AppInfo {
        get{
            let info = AppInfo("com.stells.batch.hello", self)
            info.displayName = "Hello Batch"
            info.iconImage = ImageSourceItem("batch_app_icon.pdf")
            return info
        }
    }

    //HELLO: In the near future, multiple Task will be supported.
    public static var taskClass: Task.Type {

        HelloVariousTask<HelloTaskParameter, HelloTaskResult>.self
        HelloVariousTask<HelloCustomTaskParameter, HelloCustomTaskResult>.self
        HelloParameterSpecificTask<HelloCustomTaskParameter>.self
        HelloAsyncTask.self

        return HelloTask.self
    }

    public func finalizeTasks(_ response: AppTaskResult, _ asyncSignal: TaskAsyncSignalable) -> AppTaskResult {

        return response
    }
}

//HELLO: Restricted apps own parameter type
public class HelloTypedBatchApp: HelloBatchApp, TypedApp {
    public typealias ParamType = HelloTaskParameter
    public static var paramClass: ParamType.Type{ return ParamType.self }
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

//HELLO: HelloVariousTask - Generic + Fully protocolized Task
protocol HelloCustomTaskParameter: TaskParam {

}

protocol HelloCustomTaskResult: TaskResultable{

}

private class HelloVariousTask<CustomParameterType, CustomResultType>: TaskPrototype, TypedTask{
    typealias ParamType = CustomParameterType
    typealias ResultType = CustomResultType

    public func cancel(_ async: TaskAsyncSignalable?){}

    func perform<CustomParameterType, CustomResultType>(_ param:CustomParameterType, _ async: TaskAsyncSignalable?) throws -> CustomResultType? {
        return nil
    }
}

private class HelloParameterSpecificTask<T> : HelloVariousTask<T, HelloCustomTaskResult>{

}

private extension HelloVariousTask where CustomParameterType:HelloCustomTaskParameter, CustomResultType:HelloCustomTaskResult {

    func perform(_ param: HelloCustomTaskParameter, _ async: TaskAsyncSignalable?) throws -> HelloCustomTaskResult?  {
        return nil
    }
}

//HELLO: Go infinity Tasks ...