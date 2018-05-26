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

public protocol AppInfoSchemeKey {
    var identifier:String {get}
}

public protocol AppInfoSchemeValues {
    var appType: App.Type {get}
    var version:String {get}
    var phase: AppProductPhase {get}
    var displayName:String {get}
    var icon:ImageSourceable? {get}
    var policy:AppPolicy {get}
}

public struct AppInfoKey: AppInfoSchemeKey{
    public private(set) var identifier: String
}

public struct AppInfoValues: AppInfoSchemeValues {
    public private(set) var appType: App.Type
    public private(set) var version: String = ""
    public private(set) var phase: AppProductPhase
    public private(set) var displayName: String = ""
    public private(set) var icon: ImageSourceable? = nil
    public private(set) var policy: AppPolicy
    public private(set) var minOSVersion: OperatingSystemVersion?
}

public typealias AppInfoScheme = AppInfoSchemeKey & AppInfoSchemeValues

//TODO: Auto-generate from own App class
public struct AppInfo: Hashable, AppInfoScheme {
    public let identifier:String
    public let version:String
    public let phase: AppProductPhase
    public let appType: App.Type
    public let displayName:String
    public var icon:ImageSourceable?
    public let policy:AppPolicy
    public let minOSVersion:OperatingSystemVersion?

    public var hashValue: Int {
        return self.identifier.hashValue
    }

    public static func ==(lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

public struct AppPolicy {
    static let `default` = AppPolicy(lifeCycle: AppLifecyclePolicy.default, task: TaskPolicy.default)

    public let lifeCycle: AppLifecyclePolicy
    public let task: TaskPolicy
}


public struct AppQuery: OptionSet, Hashable {

#if DEBUG
    static let `default`: AppQuery = [.beta, .release, .develop]
#else
    static let `default`: AppQuery = [.release]
#endif

    static let develop = AppQuery(rawValue: 1 << 0)
    static let beta = AppQuery(rawValue: 1 << 1)
    static let release = AppQuery(rawValue: 1 << 2)

    var key: AppInfoSchemeKey?
    var value: AppInfoSchemeValues?

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