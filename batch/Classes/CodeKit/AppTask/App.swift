//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol Appable {
    static var info: AppInfo { get }

    var config: TaskConfigable? { get }

    //taskClass can be changed by config
    static var taskClass: Taskable.Type { get }

    init(_ config: TaskConfigable?)
}

protocol ParamableAppable {
    associatedtype ParamType:TaskParamable
    static var paramClass: ParamType.Type { get }
}

protocol FinalizableAppable {
    func finalize(result: AppTaskResult, _ asyncSignal: TaskAsyncSignalable) -> AppTaskResult
}

public class AppPrototype: ItemObject {
    private(set) public var config: TaskConfigable?

    required public init(_ config: TaskConfigable?=nil){
        self.config = config
        super.init()
    }
}

public struct AppInfo: Hashable {
    let identifier:String
    let appClass: Appable.Type
    let displayName:String
    let iconImage:ImageSourceItem
    let lifeCycleUnit: AppLifecycleUnit = .systemMemory

    public var hashValue: Int {
        return self.identifier.hashValue
    }

    public static func ==(lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

