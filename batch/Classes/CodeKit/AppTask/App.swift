//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol App {
    static var info: AppInfo { get }

    var config: TaskConfigable? { get }

    //taskClass can be changed by config
    static var taskClass: Task.Type { get }

    init(_ config: TaskConfigable?)
}

protocol TypedApp: App {
    associatedtype ParamType: TaskParam
    static var paramClass: ParamType.Type { get }
}

protocol FinalizableApp {
    func finalize(result: AppTaskResult, _ asyncSignal: TaskAsyncSignalable) -> AppTaskResult
}

public class AppPrototype: ItemObject {
    private(set) public var config: TaskConfigable?

    required public init(_ config: TaskConfigable?=nil){
        self.config = config
        super.init()
    }
}

public class AppInfo:ItemObject {
    private(set) public var identifier:String
    private(set) public var appClass: App.Type

    public var displayName:String?
    public var iconImage:ImageSourceItem?
    public var lifeCycleUnit: AppLifecycleUnit = .systemMemory

    required public init(_ identifier:String, _ appClass: App.Type){
        self.identifier = identifier
        self.appClass = appClass
        super.init()
    }
}
