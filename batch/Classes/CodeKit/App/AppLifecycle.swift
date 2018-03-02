//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum AppLifecycleUnit:UInt {
    case systemMemory //TODO: implement with system memory state
    case task
    case performCycle
    case permanent
}

public enum AppState: UInt {
    case develop
    case beta
    case release
}

protocol AppLifecycleDelegatable {
    func didInstantiate() -> Bool
    func willUninstantiate() -> Bool
}

final class AppLifecycleManager {
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
        return _instanceCreationQueue.sync(flags: .barrier) {
            _acquire(info)
        }
    }

    private func _acquire(_ info: AppInfo) -> App?{
        let appIdentifier = info.identifier
        let appType = info.appType

        guard let appInstance = _instances[appIdentifier] else{
            let _appInstance = appType.init()

            _instances[appIdentifier] = _appInstance

            return _appInstance
        }
        return appInstance
    }

    @discardableResult
    public func discard(_ info: AppInfo) -> Bool{
        assert(info.policy.lifeCycleUnit != .permanent, "Discarding app's life cycle mode is permanent.")
        if info.policy.lifeCycleUnit == .permanent{
            return false
        }

        return _instanceCreationQueue.sync(flags: .barrier) {
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
