//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Dispatch

public protocol AppTaskRespondable {
    var request: AppTaskRequest { get }
    var result: TaskResultable? { get }
    var info: TaskInfo { get }
}

extension AppTaskRespondable {
    public var appInfo:AppInfo{
        return self.request.appType.info
    }
}

class AppTaskWorkItem: AppTaskRespondable {
    let request:AppTaskRequest
    let info: TaskInfo
    let task: Taskable

    internal(set) public var result: TaskResultable?

    init(request:AppTaskRequest, info:TaskInfo, task:Taskable){
        self.request=request
        self.info=info
        self.task=task
    }
}

extension AppTaskWorkItem {

    // if canceled by requester, return false, passed, return true
    @discardableResult
    func response(_ state: TaskState, _ error:TaskError?=nil) -> Bool{
        task.info.state = state
        task.info.error = error

        var canceled = false
        request.responseHandler?(self, &canceled)
        return !canceled
    }

    static func ==(lhs: AppTaskWorkItem, rhs: AppTaskWorkItem) -> Bool {
        let lhsInfo = lhs.info, rhsInfo = rhs.info
        return lhsInfo.token == rhsInfo.token
                && lhsInfo.requestToken == rhsInfo.requestToken
                && lhsInfo.taskType == rhs.info.taskType
                && lhsInfo.state == rhsInfo.state
    }
}

/*
    Reactable
*/
public typealias AppTaskReactableProgressHanlder = (
        _ progressedResult: AppTaskRespondable
        , _ progress:Float
        , _ remainedResponses:[AppTaskRespondable]
        , _ completedResponses:[AppTaskRespondable]
) -> Void

public typealias AppTaskReactableFinishHandler = (
        _ byApps:[AppInfo: [AppTaskRespondable]]
        , _ forAllResponses:[AppTaskRespondable]
) -> Void

public protocol AppTaskReactable {
    var targetQueue:DispatchQueue? { get }

    var progressHandler: AppTaskReactableProgressHanlder? { get }
    func when(progress:@escaping AppTaskReactableProgressHanlder) -> AppTaskReactable

    var finishHandler: AppTaskReactableFinishHandler?  { get }
    func when(finish:@escaping AppTaskReactableFinishHandler) -> AppTaskReactable
}

extension AppTaskReactable{
    public var targetQueue:DispatchQueue{
        get {
            return self.targetQueue ?? DispatchQueue.main
        }
    }
}

//TODO: custom queue when calling back
public class AppTaskReaction: ItemObject, AppTaskReactable {
    internal(set) public var targetQueue:DispatchQueue?
    
    private(set) public var progressHandler: AppTaskReactableProgressHanlder?

    @discardableResult
    public func when(progress:@escaping AppTaskReactableProgressHanlder) -> AppTaskReactable {
        self.progressHandler = progress
        return self
    }

    private(set) public var finishHandler: AppTaskReactableFinishHandler?

    @discardableResult
    public func when(finish:@escaping AppTaskReactableFinishHandler) -> AppTaskReactable {
        self.finishHandler = finish
        return self
    }

    public init(finish: AppTaskReactableFinishHandler?=nil){
        super.init()
        if let _finish = finish{
            self.when(finish:_finish)
        }
    }

    public init(queue:DispatchQueue?=DispatchQueue.main, finish: AppTaskReactableFinishHandler?=nil){
        super.init()
        self.targetQueue = queue
        if let _finish = finish{
            self.when(finish:_finish)
        }
    }
}
