//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum AppLifecycleUnit:UInt {
    case systemMemory
    case task
    case performCycle
    case permanent
}

protocol AppLifecycleDelegatable {
    func didInstantiate() -> Bool
    func willUninstantiate() -> Bool
}

public final class AppLifecycleManager {
    public static let shared = AppLifecycleManager()

    private var _instanceCreationQueue:DispatchQueue
    private var _instances:[String: App]

    private init() {
        _instances = [:]
        //THINK: semaphore vs current_queue?
        _instanceCreationQueue = DispatchQueue(label: "com.stells.internal__\(type(of: self))", attributes: .concurrent)
    }

    public var acquired:[String]{
        get{
            return _instanceCreationQueue.sync(flags: .barrier) {
                _instances.map { e -> String in e.0 }
            }
        }
    }

    public func acquire(_ info: AppInfo) -> App?{
        return _instanceCreationQueue.sync(flags: .barrier) { [unowned info] in
            _acquire(info)
        }
    }

    private func _acquire(_ info: AppInfo) -> App?{
        assert(info.identifier != nil, "app identifier is empty")
        assert(info.appClass != nil, "app class is empty")

        let appIdentifier = info.identifier
        let appClass = info.appClass

        guard let appInstance = _instances[appIdentifier] else{
            let _appInstance = appClass.init(nil)

            _instances[appIdentifier] = _appInstance

            return _appInstance
        }
        return appInstance
    }


    public func discard(_ info: AppInfo) -> Bool{
        assert(info.lifeCycleUnit != .permanent, "Discarding app's life cycle mode is permanent.")
        if info.lifeCycleUnit == .permanent{
            return false
        }

        return _instanceCreationQueue.sync(flags: .barrier) { [unowned info] in
            _discard(info)
        }
    }

    public func discardAll() -> [Bool]{
        return _instanceCreationQueue.sync(flags: .barrier) {
            _instances.map { e -> Bool in
                let _appInstance = e.1
                let info = type(of: _appInstance).info
                return _discard(info)
            }
        }
    }

    private func _discard(_ info: AppInfo) -> Bool{
        if _instances.keys.contains(info.identifier){
            _instances.removeValue(forKey: info.identifier)
            return true
        }
        return false
    }
}
