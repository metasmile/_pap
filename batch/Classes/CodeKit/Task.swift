//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum TaskState: UInt{
    case unqueued
    case idling
    case performing
    case cancelled
    case failed
    case completed
}

public enum TaskLoad: UInt{
    case light
    case normal
    case heavy
    case exclusive
}

public enum TaskError: Error {
    case precondition
    case exception
    case timeout
}

public protocol Taskable {
    var info: TaskInfo {  get }

    init(_ info: TaskInfo)

    func perform(_ param: TaskParamable, _ async: TaskAsyncSignalable?) throws -> TaskResultable?

    func cancel(_ async: TaskAsyncSignalable?)
}

public class TaskPrototype: Item<TaskInfo> {
    private(set) public var info: TaskInfo

    required public init(_ info: TaskInfo){
        self.info = info
        super.init()
    }
}

public final class TaskRequest<AppClassType, ParameterType, ResponseType>: ItemObject {
    public typealias ResponseHandler = (ResponseType, _ cancel:inout Bool) -> Void

    private(set) public var appClass:AppClassType
    private(set) var responseHandler:ResponseHandler?
    private(set) public var param:ParameterType
    private(set) public var token:String

    required public init(_ appClass:AppClassType, _ param:ParameterType){
        self.appClass = appClass
        self.param = param
        self.token = UUID().uuidString
    }

    convenience public init(_ appClass:AppClassType,
                            _ param:ParameterType,
                            _ responseHandler:@escaping ResponseHandler) {

        self.init(appClass,param)
        self.responseHandler = responseHandler
    }
}

/*
 app task parameter
 */

public protocol TaskConfigable {

}

public protocol TaskParamable{}


//internal
public protocol TaskResultable {}

/*
 app task
 */

//TaskLoad
public class TaskInfo: Item<String> {
    private(set) public var token:String
    private(set) public var requestToken:String
    private(set) public var taskType: Taskable.Type

    internal(set) public var state: TaskState = .unqueued
    internal(set) public var queueLabel:String?

    required public init(_ requestToken: String, _ taskType: Taskable.Type){
        self.requestToken = requestToken
        self.taskType = taskType
        self.token = UUID().uuidString
        super.init()
    }
}

//task - async
public protocol TaskSignalable {}
public protocol TaskAsyncSignalable: TaskSignalable {
    var began:Bool { get }
    func begin()
    
    func stopUntilEnd()
    
    @discardableResult 
    func end() -> Self
}

public protocol TaskSignalControllable {
    func done()
    
    @discardableResult
    func finally(_ queue:DispatchQueue?,_ completion: DispatchWorkItem) -> Self
}

public final class TaskDefaultSignal {
    internal let dispatchGroup:DispatchGroup = DispatchGroup()
    private let _offsetSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.internal__sync_queue_\(UUID().uuidString)")
    private var offset:Int = 0
}

extension TaskDefaultSignal: TaskAsyncSignalable, TaskSignalControllable {
    public var began:Bool {
        return offset>0
    }

    private func setOffset(_ increment:Bool) -> Bool{
        return _offsetSyncQueue.sync(flags: .barrier) {
            assert(offset>=0,"All state of offset must be >= 0")
            let decre = !increment && offset>0
            let incre = increment && offset>=0
            let executed = incre || decre
            if executed{
                offset += increment ? 1 : -1
            }
            return executed
        }
    }

    public func begin(){
        if setOffset(true) {
            dispatchGroup.enter()
        }
    }

    public func end() -> Self{
        if setOffset(false) {
            dispatchGroup.leave()
        }
        return self
    }
    
    public func stopUntilEnd() {
        assert(self.began,"stopUntilEnd() was called before begin(), or, after end() in same queue.")
        if self.began{
            dispatchGroup.wait()
        }
    }

    public func done() {
        while end().began { }
    }

    public func finally(_ queue:DispatchQueue?,_ completion: DispatchWorkItem) -> Self{
        let targetQueue = queue ?? DispatchQueue.main
        if self.began {
            dispatchGroup.notify(queue: targetQueue, work: completion)
        }else{
            targetQueue.async(execute: completion)
        }
        return self
    }
}

