//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum BatchTaskState: UInt{
    case unqueued
    case idling
    case performing
    case cancelled
    case failed
    case completed
}

public enum BatchTaskLoad: UInt{
    case light
    case normal
    case heavy
    case exclusive
}


/*
 app task parameter
 */

public protocol BatchTaskParameterable: Sourceable {
    var sources:[Sourceable]? { set get }
    var configs:[BatchAppConfigable]? { set get }
}

public class BatchTaskParameter: Item<[Sourceable]>, BatchTaskParameterable {
    public var sources: [Sourceable]?
    public var configs: [BatchAppConfigable]?

    override func bind(_ bindingObject: [Sourceable]?) -> [Sourceable]? {
        self.sources = bindingObject
        return bindingObject
    }
}

/*
app task responsable
*/
public enum BatchTaskResultState: UInt{
    case remained
    case finished
}

//internal
public protocol BatchTaskResultable: Sourceable {
    var results:[Sourceable]? { set get }
}

//final
public protocol BatchTaskRespondable{
    var result:BatchTaskResultable? { get }
    var info:BatchTaskInfo { get }
}

public protocol BatchAppRespondable{
    var request:BatchAppTaskRequest { get }
    var info:BatchTaskInfo  { get }
    var appInfo:BatchAppInfo { get }
}

extension BatchAppRespondable{
    var appInfo:BatchAppInfo {
        get{
            return self.request.appClass.info
        }
    }
}


/*
 app task
 */

//TaskLoad
public class BatchTaskInfo: Item<String> {
    private(set) public var token:String
    private(set) public var requestToken:String
    private(set) public var taskType:BatchTaskable.Type

    internal(set) public var state:BatchTaskState = .unqueued
    internal(set) public var queueLabel:String?

    required public init(_ requestToken: String, _ taskType:BatchTaskable.Type){
        self.requestToken = requestToken
        self.taskType = taskType
        self.token = UUID().uuidString
        super.init()
    }
}

//task - async
public protocol BatchTaskSignalable {}
public protocol BatchTaskAsyncSignalable: BatchTaskSignalable {
    var began:Bool { get }
    func begin()
    func end() -> Self
    func stopUntilEnd()
}

public protocol BatchTaskSignalControllable {
    func done()
    func finally(_ queue:DispatchQueue?,_ completion: DispatchWorkItem) -> Self
}

class BatchTaskDefaultSignal{
    internal let dispatchGroup:DispatchGroup = DispatchGroup()
    private let _offsetSyncQueue:DispatchQueue = DispatchQueue(label:"com.stells.internal__sync_queue_\(UUID().uuidString)")
    private var offset:Int = 0
}

extension BatchTaskDefaultSignal : BatchTaskAsyncSignalable, BatchTaskSignalControllable{
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

//resource
public enum BatchTaskError: Error {
    case precondition
    case exception
    case timeout
}

public protocol BatchTaskable{
    var info: BatchTaskInfo {  get }

    init(_ info: BatchTaskInfo)

    func perform(_ param:BatchTaskParameterable, _ async:BatchTaskAsyncSignalable?) throws -> BatchTaskResultable?

    func cancel(_ async:BatchTaskAsyncSignalable?)
}

public class BatchTaskPrototype: Item<BatchTaskInfo> {
    private(set) public var info: BatchTaskInfo

    required public init(_ info: BatchTaskInfo){
        self.info = info
        super.init()
    }
}

public class BatchTaskRequestPrototype<AppClassType, ParameterType, ResponseType>: ItemObject {
    public typealias ResponseHandler = (ResponseType,_ cancel:inout Bool) -> Void
    private(set) public var appClass:AppClassType
    private(set) internal var responseHandler:ResponseHandler?
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