//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public class AppInfo:ItemObject {
    private(set) public var identifier:String
    private(set) public var appClass: App.Type

    public var displayName:String?
    public var iconImage:ImageSourceItem?
    public var lifeCycleUnit:BatchAppLifecycleUnit = .systemMemory

    required public init(_ identifier:String, _ appClass: App.Type){
        self.identifier = identifier
        self.appClass = appClass
        super.init()
    }
}

public class App: ItemObject, AppTaskable {
    private(set) public var config: TaskConfigable?

    public class var info: AppInfo {
        fatalError("Subclasses need to implement the \(#function) method.")
    }

    required public init(_ config: TaskConfigable?=nil){
        self.config = config
        super.init()
    }

    public func taskClass() -> Taskable.Type{
        fatalError("Subclasses need to implement the \(#function) method.")
    }

    public func instantiateTask(_ requestToken:String) -> Taskable? {
        let taskClass = self.taskClass()
        return taskClass.init(TaskInfo(requestToken, taskClass.self))
    }
}

public struct AppResult {
    internal(set) public var info: AppInfo
    internal(set) public var results:[TaskRespondable]
}

protocol AppTaskable {
    func taskClass() -> Taskable.Type
    func instantiateTask(_ requestToken:String) -> Taskable?
}

protocol AppFinalizable {
    func finalizeTasks(_ response: AppResult, _ asyncSignal: TaskAsyncSignalable) -> AppResult
}

