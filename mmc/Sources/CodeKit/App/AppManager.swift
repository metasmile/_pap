//
// Created by BLACKGENE on 08/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public struct AppManagerConfig{
    var appCollection:[App.Type]?
    var taskManager:AppTaskManager?
}

protocol AppManagerConfigurable where Self:AppManager {
    func configure() -> AppManagerConfig?
}

open class AppManager: NSObject, SelectableCollection {

    override init(){
        super.init()

        var initializingApps = [App.Type]()

        //AppManagerConfigurable
        if let configurable = (self as? AppManagerConfigurable)?.configure(){
            if let appCollection = configurable.appCollection{
                initializingApps += appCollection
            }

            if let taskManager = configurable.taskManager{
                _task = taskManager
            }
        }else{
            assert(!(self is AppManagerConfigurable), "This AppManager conforms \(AppManagerConfigurable.self) but config is nil.")
        }

        //check and finally adds
        _apps += initializingApps.filter { app in
            if let minVersion = app.info.minOSVersion{
                return ProcessInfo().operatingSystemVersion >= minVersion
            }
            return true
        }

        //check identifier is unique
        assert(_apps.count == Set(_apps.map({ $0.info.identifier })).count, "[!] Duplicated App Identifier Found.")

        //boot with appManager
        for appManagedAppType in _apps.compactMap ({ app -> ManagerConfigurableApp.Type? in
            return app as? ManagerConfigurableApp.Type
        }){
            appManagedAppType.didConfigure(with: self)
        }

        //finally select default app if possible
        assert(_apps.count > 0, "[!] Undefined any apps")
        if current == nil && _apps.count > 0 {
            current = _apps.first
        }

        //add nofitication for memory warning
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: self, queue: .main) { [weak self] notification in
            if let _self = self{
                for app in _self._apps where app != _self.current && app.info.policy.lifeCycle.instance == .memoryWarning {
                    AppLifecycleManager.shared.discard(app.info)
                }
            }
        }
    }

    private var _apps = [App.Type]()

    private(set) public var previous: App.Type?
    public var previousIndex: Int? {
        return _apps.index { previous == $0 }
    }

    @objc dynamic
    public private(set) var currentIdentifier: String?

    private var currentLaunchOption: AppLaunchOptions?

    public func setCurrent(current:App.Type, with launchOption: AppLaunchOptions){
        self.currentLaunchOption = launchOption
        self.current = current
        self.currentLaunchOption = nil
    }

    public var current: App.Type?
    {
        willSet {
            assert(newValue == nil || _apps.contains { appType in appType == newValue },"Given current app \(String(describing:newValue)) is not contained in app collection")
        }
        didSet {
            guard previous == nil || oldValue != current else { return }

            // #1 - call willResign
            self.getInstance(oldValue, as: LaunchableApp.self)?.didResign(current: current)

            // #2 - assign previous
            self.previous = oldValue

            // #3 - discard previous if needed
            if let previous = self.previous, previous.info.policy.lifeCycle.instance == .availability {
                AppLifecycleManager.shared.discard(previous.info)
            }

            // #4 - touch current version
            var defaultsOfCurrent = self.currentDefaults
            defaultsOfCurrent?.touchedVersion = current?.info.version

            // #5 - capture identifier
            let currentIdentifier = self.current?.info.identifier

            DispatchQueue.mainAsyncIfNot {
                // #6 - notify current identifier
                self.currentIdentifier = currentIdentifier
            }

            // #7 - acquire current instance firstly -> notify didLaunch.
            self.getInstance(self.current, as: LaunchableApp.self)?.didLaunch(previous:self.previous, withOption:self.currentLaunchOption)

            // #8 - discard currentLaunchOption already passed
            self.currentLaunchOption = nil
        }
    }

    public var currentIndex: Int? {
        get {
            return _apps.index { current == $0 }
        }
        set {
            if let index = newValue, _apps.indices.contains(index) {
                current = _apps[index]
            }else{
                current = nil
            }
        }
    }

    /*
        INFO:
        Avoid directly store as a property if possible.
        But when must be stored with class or struct, use weak reference.

        TODO:
        Should return the proxy instance.
    */
    public func currentInstanceAs<T>(_ type:T.Type) -> T?{
        return getInstance(current, as: type)
    }

    public var currentDefaults: AppDefaults? {
        return (current as? PersistableApp.Type)?.defaults
    }

    private func getInstance<T>(_ appType:App.Type?, as protocol:T.Type) -> T?{
        guard let appType = appType else { return nil }
        return AppLifecycleManager.shared.acquire(appType.info) as? T
    }

    public func reset() {
        self.current = nil
        self.previous = nil
    }

    /*
        apps(), apps(nil)   -> all
        apps(by: query)     -> queried
    */
    //TODO: all keys, value match by AppInfo
    public func apps(by query: AppQuery?=nil) -> [App.Type]{
        return query == nil ? self._apps : self._apps.filter { app in
            guard let query = query else{ return false }

            //productPhase
            if let _ = AppQuery.phases.filter({ query.contains($0.key) }).first(where: { app.info.phase == $0.value }) {
                return true
            }

            return false
        }
    }

    public func persistedStatus(for app:App.Type) -> AppPersistedStatus {
        return (app as? PersistableApp.Type)?.status ?? .unsupported
    }

    // Task
    public var task:AppTaskManager{
        return _task
    }

    private lazy var _task = AppTaskManager({ () -> UInt in
        //https://en.wikipedia.org/wiki/List_of_iOS_devices
        let remainingMem = ProcessInfo.processInfo.physicalRemainingMemory/(1024*1024)

        switch (ProcessInfo.processInfo.processorCount){
                //iPhone 8	iPhone 8 Plus	iPhone X
        case 6 where remainingMem >= 2000:
            return 4
        case 6 where remainingMem >= 1000:
            return 3
        case 6 where remainingMem < 1000:
            return 2

                //iPhone 7	iPhone 7 Plus
        case 4 where remainingMem >= 2000:
            // a case for iPhone 7 Plus
            return 4
        case 4 where remainingMem >= 1000:
            // a case for iPhone 7 Plus
            return 3
        case 4:
            // a case for iPhone 7 Plus
            return 2

        case ..<4 where remainingMem>1000:
            return 3

        case ..<4:
            return 2

        default:
            return 1
        }
    }())
}


/*
    Lifecycle
*/
protocol AppLifecycleManagerAllowingInstanceAccessor {}

extension App{
    static var isInstanceAcquired:Bool{
        return AppLifecycleManager.shared.acquiredTypes.contains { appType in
            return appType == self.info.appType
        }
    }

    static func getInstance(user: AppLifecycleManagerAllowingInstanceAccessor.Type) -> App?{
        return AppLifecycleManager.shared.instancesAccessQueue.sync{
            return AppLifecycleManager.shared.instances[self.info.identifier]
        }
    }
}

public struct AppLifecyclePolicy{
    public let instance: AppInstanceLifecycleUnit

    public static var `default`:AppLifecyclePolicy{
        return AppLifecyclePolicy(instance: .memoryWarning)
    }
}

public enum AppInstanceLifecycleUnit:UInt {
    case availability
    case memoryWarning
    case permanent
}

private final class AppLifecycleManager {
    static let shared = AppLifecycleManager()
    var instancesAccessQueue:DispatchQueue
    var instances:[String: App]

    private init() {
        instances = [:]
        //THINK: semaphore vs current_queue?
        instancesAccessQueue = DispatchQueue(label: "com.stells.internal__\(type(of: self))",qos: .userInteractive)
    }

    var acquiredTypes:[App.Type]{
        return instancesAccessQueue.sync {
            instances.map { type(of: $0.1) }
        }
    }

    func acquire(_ info: AppInfo) -> App?{
        return _acquire(info)
    }

    private func _acquire(_ info: AppInfo) -> App?{
        return instancesAccessQueue.sync {
            let appIdentifier = info.identifier
            let appType = info.appType

            guard let appInstance = instances[appIdentifier] else{
                let _appInstance = appType.init()

                if let delegation = _appInstance as? LifecycleManageableApp, delegation.willAcquire() == false{
                    return nil
                }

                instancesAccessQueue.async(flags:.barrier){
                    self.instances[appIdentifier] = _appInstance
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
        return instancesAccessQueue.sync{
            let identifier = info.identifier
            guard let appInstance = instances[identifier] else { return false }

            if info.policy.lifeCycle.instance == .permanent{
                return false
            }

            if let delegation = appInstance as? LifecycleManageableApp, delegation.willDiscard() == false{
                return false
            }

            instancesAccessQueue.async(flags:.barrier){
                self.instances.removeValue(forKey: identifier)
            }
            return true
        }
    }
}
