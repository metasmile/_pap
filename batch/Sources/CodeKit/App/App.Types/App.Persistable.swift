//
// Created by BLACKGENE on 23/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

public protocol AppDefaults: DefaultsAutoProperty{
    var version:String? {set get}
}

public extension AppDefaults where Self:Defaults{
    public var version: String? {
        set(newValue){ set(newValue) } get{ return get() }
    }
}

public protocol PersistableApp{
    var defaults:AppDefaults? {get}
}

private struct _AppDefaultsCollection {
    fileprivate static var defaults = _AppDefaultsCollection()
    fileprivate var collection = [String:AppDefaults]()
}

extension PersistableApp where Self:App{
    public var defaults:AppDefaults? {
        let appId = type(of: self).info.displayName
        var _defaults:AppDefaults? = _AppDefaultsCollection.defaults.collection[appId]
        if _defaults == nil{
            if let userDefaults = UserDefaults(suiteName: appId){
                _defaults = Defaults(userDefaults: userDefaults)
                _AppDefaultsCollection.defaults.collection[appId] = _defaults
            }
        }
        return _defaults
    }
}