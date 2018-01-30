//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


public protocol AppTaskResultable{
    associatedtype ResultType
    var info: AppInfo {get}
    var results:ResultType {get}
}

public struct AppTaskResult: AppTaskResultable {
    public typealias ResultType = [TaskRespondable]
    internal(set) public var info: AppInfo
    internal(set) public var results:ResultType
}

/*
    WorkItem
*/
struct AppTaskWorkItem: TaskRespondable, AppTaskRespondable, Equatable {
    let request:AppTaskRequest
    let info: TaskInfo
    let task: Taskable

    internal(set) public var result: TaskResultable?
}

extension AppTaskWorkItem {

    // if canceled by requester, return false, passed, return true
    func response(_ state: TaskState) -> Bool{
        task.info.state = state
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

struct AppTaskResultItem {
    var finished:[AppTaskWorkItem]?
}


/*
    Respondable
*/
public protocol AppTaskRespondable {
    var request:AppTaskRequest { get }
    var info: TaskInfo { get }
    var appInfo: AppInfo { get }
}

extension AppTaskRespondable {
    var appInfo: AppInfo {
        get{
            return self.request.appClass.info
        }
    }
}

/*
    Reactable
*/
public typealias AppTaskReactableProgressHanlder = (
        _ result: AppTaskResult
        , _ progress:Float
        , _ remained:[AppTaskRespondable]
        , _ finished:[AppTaskRespondable]
) -> Void

public typealias AppTaskReactableFinishHandler = (
        _ resultsByApps:[AppInfo:AppTaskResult]
        , _ allResults:[TaskResultable]
        , _ for:[AppTaskRespondable]
) -> Void

public protocol AppTaskReactable {
    var progressHandler: AppTaskReactableProgressHanlder? { get }
    func when(progress:@escaping AppTaskReactableProgressHanlder) -> AppTaskReactable

    var finishHandler: AppTaskReactableFinishHandler?  { get }
    func when(finish:@escaping AppTaskReactableFinishHandler) -> AppTaskReactable
}

public class AppTaskReaction: ItemObject, AppTaskReactable {
    private(set) public var progressHandler: AppTaskReactableProgressHanlder?

    public func when(progress:@escaping AppTaskReactableProgressHanlder) -> AppTaskReactable {
        self.progressHandler = progress
        return self
    }

    private(set) public var finishHandler: AppTaskReactableFinishHandler?

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
}