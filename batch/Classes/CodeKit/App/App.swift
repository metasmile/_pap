//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol App {
    static var info: AppInfo { get }

    var config: TaskConfigable? { get }

    //taskType can be changed by config
    static var taskType: Taskable.Type { get }

    static var paramType: TaskParamable.Type { get }

    init(_ config: TaskConfigable?)
}

public protocol FinalizableApp {
    func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable]
}

extension Array where Element == AppTaskRespondable{
    func isAnyTask(inState:TaskState) -> Bool{
        for e in self{
            if e.info.state == inState{
                return true
            }
        }
        return false
    }

    var defaultTaskPolicy: TaskPolicy{
        return self.first?.appInfo.policy.task ?? TaskPolicy.default
    }
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
    let version:String
    let state:AppState
    let appType: App.Type
    let displayName:String
    let icon:ImageSourceable?
    let policy:AppPolicy

    public var hashValue: Int {
        return self.identifier.hashValue
    }

    public static func ==(lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

public struct AppPolicy {
    static let `default` = AppPolicy(lifeCycleUnit: .systemMemory, task: TaskPolicy.default)

    public let lifeCycleUnit: AppLifecycleUnit
    public let task: TaskPolicy
}