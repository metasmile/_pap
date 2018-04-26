//
// Created by BLACKGENE on 23/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

public protocol AppDefaults: DefaultsAutoProperty{
    var touchedVersion:String? {set get}
}

public extension AppDefaults where Self:Defaults{
    public var touchedVersion: String? {
        set{ set(newValue) } get{ return get() }
    }
}

public enum AppPersistedStatus {
    case unsupported

    case released
    case updated
    case used
}

public protocol PersistableApp{
    static var defaults:AppDefaults {get}
    static var status: AppPersistedStatus {get}
}

private struct _AppDefaultsCollection {
    fileprivate static var defaults = _AppDefaultsCollection()
    fileprivate var collection = [String:AppDefaults]()
}

extension PersistableApp where Self:App{
    public static var status: AppPersistedStatus {
        let touchedVersion = self.defaults.touchedVersion
        if self.info.phase == .release{
            if touchedVersion == nil{
                return .released
            }else if touchedVersion != self.info.version{
                return .updated
            }else if touchedVersion == self.info.version{
                return .used
            }else{
                assert(false, "Unusual status for touchedVersion \(String(describing: touchedVersion))")
                return .unsupported
            }
        }else{
            return .unsupported
        }
    }

    public static var defaults:AppDefaults {
        let defaultsId = "\(String(describing: PersistableApp.self))_\(self.info.identifier)"

        if let defaults = _AppDefaultsCollection.defaults.collection[defaultsId]{
            return defaults
        }

        let userDefaults = UserDefaults(suiteName: defaultsId)
        assert(userDefaults != nil,"userDefaults suiteName:\(defaultsId) didn't create at \(String(describing: self))")

        let defaults = Defaults(userDefaults: userDefaults ?? UserDefaults())
        _AppDefaultsCollection.defaults.collection[defaultsId] = defaults
        return defaults
    }
}
