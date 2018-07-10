//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum AppTaskState: UInt{
    case unqueued
    case idling
    case performing
    case cancelled
    case failed
    case completed
}

public enum AppTaskLoad: UInt{
    case light
    case normal
    case heavy
    case exclusive
}

public enum AppTaskError: Error {
    case rejectedParam
    case invalidParam
    case invalidResult
    case internalException
    case timeout
    case unknown
}


/*
    The priority of TaskPolicy

    AppTaskRequest > App > Task
*/

public struct AppTaskPolicy {
    static let `default` = AppTaskPolicy(
            cancellation: .shallow,
            priority: .normal,
            estimatedConcurrencyCount: nil
    )

    public enum Cancellation {
        case verbose
        case shallow
    }
    public let cancellation: Cancellation

    /*
     when priority == .high if concurrencyCount == 1 -> highest priority will be guaranteed
     when priority == .high if concurrencyCount > 1 -> highest priority will not be guaranteed
    */
    public enum Priority {
        case normal
        case high
    }

    public var priority: Priority = .normal

    /*
        estimatedConcurrencyCount means "preferred" concurrencyCount.
        if estimatedConcurrencyCount == 1, the task always assign to specific queue.
        if concurrencyCount was 0 or bigger than AppManager.maxConcurrentCount, ignored.
    */
    public var estimatedConcurrencyCount: Int? {
        didSet {
            assert(estimatedConcurrencyCount == nil || estimatedConcurrencyCount! > 0, "preferredConcurrencyCount must be undefined(nil) or bigger than 0")
            if estimatedConcurrencyCount == 0{
                estimatedConcurrencyCount = 1
            }
        }
    }
}

public protocol _AppTaskable {
    init(_ info: AppTaskInfo)

    func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable?

    func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable)
}

public protocol AppTaskable: _AppTaskable {
    var info: AppTaskInfo {  get }
}

public class AppTaskPrototype: Item<AppTaskInfo> {
    private(set) public var info: AppTaskInfo

    required public init(_ info: AppTaskInfo){
        self.info = info
        super.init()
    }
}

public typealias AppTaskRequest = AppTaskRequestable<App.Type, AppTaskParamable, AppTaskRespondable>

public final class AppTaskRequestable<AppType, ParameterType, ResponseType>: ItemObject {
    public typealias ResponseHandler = (ResponseType, _ cancel:inout Bool) -> Void

    private(set) public var appType: AppType
    private(set) public var taskPolicy: AppTaskPolicy?
    private(set) var responseHandler:ResponseHandler?
    private(set) public var param:ParameterType
    private(set) public var token:String

    required public init(_ appType: AppType, _ param:ParameterType){
        self.appType = appType
        self.param = param
        self.token = UUID().uuidString
    }

    convenience public init(_ appType: AppType,
                            _ param:ParameterType,
                            _ responseHandler:@escaping ResponseHandler) {

        self.init(appType,param)
        self.responseHandler = responseHandler
    }

    convenience public init(_ appType: AppType,
                            _ taskPolicy: AppTaskPolicy,
                            _ param:ParameterType,
                            _ responseHandler:@escaping ResponseHandler) {

        self.init(appType,param,responseHandler)
        self.taskPolicy = taskPolicy
    }
}

/*
 app task parameter
 */

public protocol AppTaskParamable {}


//internal
public protocol AppTaskResultable {}

/*
 app task
 */

//TaskLoad
public class AppTaskInfo: Item<String> {
    private(set) public var token:String
    private(set) public var requestToken:String
    private(set) public var requestParam: AppTaskParamable
    private(set) public var taskType: AppTaskable.Type
    private(set) public var appType: App.Type

    internal(set) public var state: AppTaskState = .unqueued
    internal(set) public var policy: AppTaskPolicy = AppTaskPolicy.default
    internal(set) public var queueLabel:String?
    internal(set) var error: AppTaskError?

    required public init(_ requestToken: String, _ requestParam: AppTaskParamable, _ taskType: AppTaskable.Type, _ appType: App.Type){
        self.requestToken = requestToken
        self.requestParam = requestParam
        self.taskType = taskType
        self.token = UUID().uuidString
        self.appType = appType
        super.init()
    }

}
