//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct AppLifecyclePolicy{
    public let instance: AppInstanceLifecycleUnit

    public static var `default`:AppLifecyclePolicy{
        return AppLifecyclePolicy(instance: .memoryWarning)
    }
}

public enum AppInstanceLifecycleUnit:UInt {
    case allTasks
    case availability
    case memoryWarning
    case permanent
}

protocol AppLifecycleManagerDelegatedApp where Self:App {
    func willAcquire() -> Bool
    func willDiscard() -> Bool
}

final class AppLifecycleManager {
    static let shared = AppLifecycleManager()

    private var _instancesAccessQueue:DispatchQueue
    private var _instances:[String: App]

    private init() {
        _instances = [:]
        //THINK: semaphore vs current_queue?
        _instancesAccessQueue = DispatchQueue(label: "com.stells.internal__\(type(of: self))",qos: .userInteractive)
    }

    var acquired:[String]{
        return _instancesAccessQueue.sync {
            _instances.map { e -> String in e.0 }
        }
    }

    func acquire(_ info: AppInfo) -> App?{
        return _acquire(info)
    }

    private func _acquire(_ info: AppInfo) -> App?{
        return _instancesAccessQueue.sync {
            let appIdentifier = info.identifier
            let appType = info.appType

            guard let appInstance = _instances[appIdentifier] else{
                let _appInstance = appType.init()

                if let delegation = _appInstance as? AppLifecycleManagerDelegatedApp, delegation.willAcquire() == false{
                    return nil
                }

                _instancesAccessQueue.async(flags:.barrier){
                    self._instances[appIdentifier] = _appInstance
                }
                return _appInstance
            }
            return appInstance
        }
    }

    @discardableResult
    func discard(_ info: AppInfo) -> Bool{
        return _discard(info)
    }

    private func _discard(_ info: AppInfo) -> Bool{
        return _instancesAccessQueue.sync{
            let identifier = info.identifier
            guard let appInstance = _instances[identifier] else { return false }

            if info.policy.lifeCycle.instance == .permanent{
                return false
            }

            if let delegation = appInstance as? AppLifecycleManagerDelegatedApp, delegation.willDiscard() == false{
                return false
            }

            _instancesAccessQueue.async(flags:.barrier){
                self._instances.removeValue(forKey: identifier)
            }
            return true
        }
    }
}
