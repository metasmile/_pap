//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol App {

    init()

    static var info: AppInfo { get }

    //taskType can be changed by config
    static var taskType: Taskable.Type { get }

    static var paramType: TaskParamable.Type { get }
}

public struct AppInfo: Hashable {
    let identifier:String
    let version:String
    let phase: AppProductPhase
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


public struct AppQuery: OptionSet, Hashable {

#if DEBUG
    public static let `default`: AppQuery = [.beta, .release, .develop]
#else
    public static let `default`: AppQuery = [.release]
#endif

    public static let develop = AppQuery(rawValue: 1 << 0)
    public static let beta = AppQuery(rawValue: 1 << 1)
    public static let release = AppQuery(rawValue: 1 << 2)


    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public var hashValue: Int{
        return rawValue.hashValue
    }
    public static func ==(lhs: AppQuery, rhs: AppQuery) -> Bool{
        return lhs.hashValue==rhs.hashValue
    }
}

extension AppQuery {
    static let phases:[AppQuery:AppProductPhase] = [
        .develop:.develop,
        .beta   :.beta,
        .release:.release,
    ]
}