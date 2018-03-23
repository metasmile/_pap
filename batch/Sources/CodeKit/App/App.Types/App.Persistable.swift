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
        let defaultsId = "\(String(describing: PersistableApp.self))_\(type(of: self).info.identifier)"
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