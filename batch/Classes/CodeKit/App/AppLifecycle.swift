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

public enum AppProductPhase: UInt {
    case develop
    case beta
    case release
}

protocol AppLifecycleDelegate where Self:App {
    func willAcquire() -> Bool
    func willDiscard() -> Bool
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
        return _instanceCreationQueue.sync(flags: .barrier) {
            _instances.map { e -> String in e.0 }
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

            if let delegation = _appInstance as? AppLifecycleDelegate, delegation.willAcquire() == false{
                return nil
            }

            _instances[appIdentifier] = _appInstance
            return _appInstance
        }
        return appInstance
    }

    @discardableResult
    public func discard(_ info: AppInfo) -> Bool{
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
        let identifier = info.identifier
        guard let appInstance = _instances[identifier] else { return false }

        if info.policy.lifeCycleUnit == .permanent{
            return false
        }

        if let delegation = appInstance as? AppLifecycleDelegate, delegation.willDiscard() == false{
            return false
        }

        _instances.removeValue(forKey: identifier)
        return true
    }
}
