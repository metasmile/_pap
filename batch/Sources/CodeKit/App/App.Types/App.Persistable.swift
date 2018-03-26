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
        set(newValue){ set(newValue) } get{ return get() }
    }
}

public enum AppPersistedStatus {
    case unsupported

    case released
    case updated
    case used
}

public protocol PersistableApp{
    static var defaults:AppDefaults? {get}
    static var status: AppPersistedStatus {get}
}

private struct _AppDefaultsCollection {
    fileprivate static var defaults = _AppDefaultsCollection()
    fileprivate var collection = [String:AppDefaults]()
}

extension PersistableApp where Self:App{
    public static var status: AppPersistedStatus {
        let touchedVersion = self.defaults?.touchedVersion
        if self.info.phase == .release{
            if touchedVersion == nil{
                return .released
            }else if touchedVersion != self.info.version{
                return .updated
            }else if touchedVersion == self.info.version{
                return .used
            }else{
                assert(false, "Unusual status for touchedVersion \(touchedVersion)")
                return .unsupported
            }
        }else{
            return .unsupported
        }
    }

    public static var defaults:AppDefaults? {
        let defaultsId = "\(String(describing: PersistableApp.self))_\(self.info.identifier)"
        var _defaults:AppDefaults? = _AppDefaultsCollection.defaults.collection[defaultsId]
        if _defaults == nil{
            if let userDefaults = UserDefaults(suiteName: defaultsId){
                _defaults = Defaults(userDefaults: userDefaults)
                assert(_defaults != nil,"userDefaults id:\(defaultsId) didn't create at \(String(describing: PersistableApp.self))")
                _AppDefaultsCollection.defaults.collection[defaultsId] = _defaults
            }
        }
        return _defaults
    }
}