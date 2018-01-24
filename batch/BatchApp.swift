//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum BatchAppLifecycleUnit:UInt {
    case systemMemory
    case task
    case performCycle
    case permanent
}

public class BatchAppInfo:ItemObject {
    private(set) public var identifier:String
    private(set) public var appClass:BatchApp.Type

    public var displayName:String?
    public var iconImage:ImageSourceItem?
    public var lifeCycleUnit:BatchAppLifecycleUnit = .systemMemory

    required public init(_ identifier:String, _ appClass: BatchApp.Type){
        self.identifier = identifier
        self.appClass = appClass
        super.init()
    }
}

//BatchApp
public struct BatchAppResult {
    internal(set) public var info:BatchAppInfo
    internal(set) public var results:[BatchTaskRespondable]
}

protocol BatchAppTaskable {
    func taskClass() -> BatchTaskable.Type
    func instantiateTask(_ requestToken:String) -> BatchTaskable?
}

protocol BatchAppFinalizable {
    func finalizeTasks(_ response:BatchAppResult, _ asyncSignal:BatchTaskAsyncSignalable) -> BatchAppResult
}

protocol BatchAppLifecycleDelegatable {
    func didInstantiate() -> Bool
    func willUninstantiate() -> Bool
}

public class BatchApp: ItemObject, BatchAppTaskable {
    private(set) public var config: BatchAppConfigable?

    public class var info: BatchAppInfo{
        fatalError("Subclasses need to implement the \(#function) method.")
    }

    required public init(_ config:BatchAppConfigable?=nil){
        self.config = config
        super.init()
    }

    public func taskClass() -> BatchTaskable.Type{
        fatalError("Subclasses need to implement the \(#function) method.")
    }

    public func instantiateTask(_ requestToken:String) -> BatchTaskable? {
        let taskClass = self.taskClass()
        return taskClass.init(BatchTaskInfo(requestToken, taskClass.self))
    }
}
