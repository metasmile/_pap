//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol App {

    init()

    static var info: AppInfo { get }
}

public protocol TaskApp: App{

    //taskType can be changed by config
    static var taskType: AppTaskable.Type { get }

    static var paramType: AppTaskParamable.Type { get }
}

/*
    AppInfo
*/

public protocol AppInfoSchemeKey {
    var appType: App.Type {get}
    var identifier:String {get}
}

public protocol AppInfoSchemeValues {
    var version:String {get}
    var phase: AppProductPhase {get}
    var displayName:String {get}
    var iconBundleName:String? {get}
    var policy:AppPolicy {get}
}

public protocol AppInfoPresentableSchemeValues {
    var description: String? {get}
    var keywords:[String]? {get}
}

public protocol AppInfoAppearanceSchemeValues {
    var themeColor: UIColor? {get}
    var embossIconBundleName:String? {get}
}

public protocol AppInfoLocalizedPresentableSchemeValues{
    var localizableDisplayName: String? {get}
    var localizableDescription: String? {get}
    var localizableKeywords:[String]? {get}
}

extension AppInfoLocalizedPresentableSchemeValues where Self:AppInfoSchemeValues{
    var localizableDisplayName: String? {
        return NSLocalizedString(self.displayName, comment: "")
    }
}

extension AppInfoLocalizedPresentableSchemeValues where Self:AppInfoPresentableSchemeValues{
    var localizableDescription: String? {
        if let desc = self.description{
            return NSLocalizedString(desc, comment: "")
        }
        return nil
    }
    var localizableKeywords: [String]? {
        return keywords?.map { s -> String in
            return NSLocalizedString(s, comment: "")
        }
    }
}

//TODO: Auto-generate from own App class
public struct AppInfo: Hashable, AppInfoSchemeKey, AppInfoSchemeValues, AppInfoAppearanceSchemeValues, AppInfoPresentableSchemeValues {
    public let identifier:String
    public let version:String
    public let phase: AppProductPhase
    public let appType: App.Type
    public let displayName:String
    public var description: String?
    public var keywords:[String]?
    public var iconBundleName:String?
    public let themeColor:UIColor?
    public var embossIconBundleName:String?
    public let policy:AppPolicy
    public let minOSVersion:OperatingSystemVersion?

    public var hashValue: Int {
        return self.identifier.hashValue
    }

    public static func ==(lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

public enum AppProductPhase: UInt {
    case develop
    case beta
    case release
}

public struct AppPolicy {
    static let `default` = AppPolicy(lifeCycle: AppLifecyclePolicy.default, task: AppTaskPolicy.default)

    public let lifeCycle: AppLifecyclePolicy
    public let task: AppTaskPolicy
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