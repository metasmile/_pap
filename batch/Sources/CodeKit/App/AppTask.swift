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

class AppTaskItem: AppTaskRespondable {
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

extension AppTaskItem {

    // if canceled by requester, return false, passed, return true
    @discardableResult
    func response(_ state: TaskState, _ error:TaskError?=nil) -> Bool{
        task.info.state = state
        task.info.error = error

        var canceled = false
        request.responseHandler?(self, &canceled)
        return !canceled
    }

    static func ==(lhs: AppTaskItem, rhs: AppTaskItem) -> Bool {
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

// Appable
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

public typealias AppTaskReactableWillFinishHandler = (
        _ byApps:[AppInfo: [AppTaskRespondable]]
        , _ forAllResponses:[AppTaskRespondable]
) -> Void

public protocol AppTaskReactable {
    var progressHandler: AppTaskReactableProgressHanlder? { get }
    func when(progress:@escaping AppTaskReactableProgressHanlder) -> Self

    var willFinishHandler: AppTaskReactableWillFinishHandler?  { get }
    func will(finish:@escaping AppTaskReactableWillFinishHandler) -> Self

    var didFinishHandler: AppTaskReactableFinishHandler?  { get }
    func did(finish:@escaping AppTaskReactableFinishHandler) -> Self
}

//TODO: custom queue when calling back
public class AppTaskReaction: ItemObject, AppTaskReactable {
    internal(set) public var targetQueue:DispatchQueue?

    //progress
    private(set) public var progressHandler: AppTaskReactableProgressHanlder?

    @discardableResult
    public func when(progress:@escaping AppTaskReactableProgressHanlder) -> Self {
        self.progressHandler = progress
        return self
    }

    //finalize
    private(set) public var willFinishHandler: AppTaskReactableWillFinishHandler?

    @discardableResult
    public func will(finish:@escaping AppTaskReactableWillFinishHandler) -> Self {
        self.willFinishHandler = finish
        return self
    }

    //finish
    private(set) public var didFinishHandler: AppTaskReactableFinishHandler?

    @discardableResult
    public func did(finish:@escaping AppTaskReactableFinishHandler) -> Self {
        self.didFinishHandler = finish
        return self
    }

    public init(finish: AppTaskReactableFinishHandler?=nil){
        super.init()
        if let _finish = finish{
            self.did(finish:_finish)
        }
    }
}


