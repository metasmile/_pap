//
// Created by BLACKGENE on 26/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Dispatch
import UIKit

//TODO: more strictful parameter type for public
public struct HelloTaskParameter: TaskParamable {
    public var sources:[Sourceable]?
}

public struct HelloTaskResult: TaskResultable{
    public var results:[Sourceable]?
}

public protocol HelloTaskParam: TaskParamable {

}

public class HelloTypedBatchApp: HelloBatchApp{
    public typealias ParamType = HelloTaskParameter
    public static func paramType() -> HelloTaskParameter.Type {
        return HelloTaskParameter.self
    }
}


//HELLO: This app "HelloBatchApp" is supporting "FinalizableApp" for example PHAsset handling.
public class HelloBatchApp: App, FinalizableApp {

    public static let info = AppInfo(
            identifier: "com.stells.batch.hello"
            , version: "0.1"
            , phase: .develop
            , appType: HelloBatchApp.self
            , displayName: "Hello Batch"
            , icon: nil
            , policy: AppPolicy.default
    )

    //HELLO: In the near future, multiple Task will be supported.
    public static var taskType: Taskable.Type {

//        HelloVariousTask<HelloTaskParameter, HelloTaskResult>.self
//        HelloVariousTask<HelloCustomTaskParameter, HelloCustomTaskResult>.self
//        HelloParameterSpecificTask<HelloCustomTaskParameter>.self
        return HelloAsyncTask.self

//        return HelloTask.self
    }

    public static let paramType:TaskParamable.Type = PHAssetItem<BatchAppPHAssetState>.self


    public func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable] {

        return result
    }

    required public init(){}
}

//HELLO: Restricted apps own parameter type



//HELLO: HelloTask - Default Task
//private class HelloTask: TaskPrototype, Taskable {
//    typealias ParamType = HelloTaskParameter
//    typealias ResultType = HelloTaskResult
//
//    var property:String?
//
//    public func cancel(_ async: TaskAsyncSignalable?){
//
//    }
//
//    func perform(_ param: ParamType, _ async: TaskAsyncSignalable?) throws -> ResultType?  {
//        return nil
//    }
//}
//
////HELLO: "HelloTask-specific" task implementation
//private extension Taskable where Self==HelloTask{
//
//    func perform<T,U>(_ param: T, _ async: TaskAsyncSignalable?) throws -> U?{
//
//        //HELLO: can access property. using "where Self== HelloTask"
//        let prop = self.property
//
//        return nil
//    }
//}
//
////HELLO: more general perform implementation apart from specific task type
//private extension Taskable
//        where ParamType == HelloTaskParameter, ResultType == HelloTaskResult {
//
//    func perform(_ param: HelloTaskParameter, _ async: TaskAsyncSignalable?) throws -> HelloTaskResult?  {
//
//        return nil
//    }
//}

//HELLO: HelloAsyncTask - Async Task
private class HelloAsyncTask: TaskPrototype, Taskable {
    typealias ParamType = HelloTaskParameter
    typealias ResultType = HelloTaskResult

    public func cancel(_ param: TaskParamable, _ async: TaskAsyncSignalable?){
        //HELLO: same as "perform", all the cancellation processes are also affected by this.
    }

    public func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable? {
        return try self._perform(param as! HelloTaskParameter, async)
    }

    func _perform(_ param: HelloTaskParameter, _ async: TaskAsyncSignalable?) throws -> HelloTaskResult?  {
        var helloResult:ResultType? = nil

        //HELLO: use begin() if this task internally need async code.
        async?.begin()

        DispatchQueue.global().async {
            if let image = param.sources?.first as? ImageSourceable{
                //HELLO: process an image ... or fetch some remote resources from AFNetworking for example
                image.asUIImage

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
protocol HelloCustomTaskParameter: TaskParamable {

}

protocol HelloCustomTaskResult: TaskResultable{

}

//private class HelloVariousTask<CustomParameterType, CustomResultType>: TaskPrototype, Taskable {
//    typealias ParamType = CustomParameterType
//    typealias ResultType = CustomResultType
//
//    public func cancel(_ async: TaskAsyncSignalable?){}
//
//    func perform(_ param:CustomParameterType, _ async: TaskAsyncSignalable?) throws -> CustomResultType? {
//        return nil
//    }
//}

//private class HelloParameterSpecificTask<T> : HelloVariousTask<T, HelloCustomTaskResult>{
//
//}

//private extension HelloVariousTask where CustomParameterType:HelloCustomTaskParameter, CustomResultType:HelloCustomTaskResult {
//
//    func perform(_ param: HelloCustomTaskParameter, _ async: TaskAsyncSignalable?) throws -> HelloCustomTaskResult?  {
//        return nil
//    }
//}

//HELLO: Go infinity Tasks ...
