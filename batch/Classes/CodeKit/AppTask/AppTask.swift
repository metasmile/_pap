//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation


public struct AppTaskResult {
    internal(set) public var info: AppInfo
    internal(set) public var results:[TaskRespondable]
}

/*
    WorkItem
*/
struct AppTaskWorkItem: TaskRespondable, AppTaskRespondable, Equatable {
    let request:AppTaskRequest
    let info: TaskInfo
    let task: Taskable

    internal(set) var result: TaskResultable?
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
public protocol AppTaskReactable {
    typealias ProgressHanlder = (
            _ result: AppTaskResult
            , _ progress:Double
            , _ remained:[AppTaskRespondable]
            , _ finished:[AppTaskRespondable]
    ) -> Void

    var progressHandler:ProgressHanlder? { get }
    func when(progress:@escaping ProgressHanlder) -> AppTaskReactable

    typealias FinishHandler = (
            _ results:[AppTaskResult]
            , _ for:[AppTaskRespondable]
    ) -> Void

    var finishHandler:FinishHandler?  { get }
    func when(finish:@escaping FinishHandler) -> AppTaskReactable
}

public class AppTaskReactionItem: ItemObject, AppTaskReactable {
    private(set) public var progressHandler:ProgressHanlder?

    public func when(progress:@escaping ProgressHanlder) -> AppTaskReactable {
        self.progressHandler = progress
        return self
    }

    private(set) public var finishHandler:FinishHandler?

    public func when(finish:@escaping FinishHandler) -> AppTaskReactable {
        self.finishHandler = finish
        return self
    }

    public init(finish: FinishHandler?=nil){
        super.init()
        if let _finish = finish{
            self.when(finish:_finish)
        }
    }
}