//
// Created by BLACKGENE on 08/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct AppManagerConfig{
    var appCollection:[App.Type]?
    var taskManager:AppTaskManager?
}

protocol AppManagerConfigurable where Self:AppManager {
    func configure() -> AppManagerConfig?
}

protocol AppManagerDelegatedApp where Self:App {
    static func didConfigurate(with manager:AppManager)

    func willSetCurrent(oldCurrent:App.Type?)
    func didSetCurrent(previous:App.Type?)
}

extension AppManagerDelegatedApp {
    static func didConfigurate(with manager: AppManager) {}
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

        //boot with appManager
        for appManagedApp in _apps.compactMap ({ app -> AppManagerDelegatedApp? in
            return app as? AppManagerDelegatedApp
        }){
            type(of: appManagedApp).didConfigurate(with: self)
        }

        //finally select default app if possible
        assert(_apps.count > 0, "[!] Undefined any apps")
        if current == nil && _apps.count > 0 {
            current = _apps.first
        }
    }

    private var _apps = [App.Type]()

    private(set) public var previous: App.Type?
    public var previousIndex: Int? {
        return _apps.index { previous == $0 }
    }

    @objc dynamic
    public private(set) var currentIdentifier: String?

    public var current: App.Type?
    {
        willSet {
            assert(newValue == nil || _apps.contains { appType in appType == newValue },"Given current app \(String(describing:newValue)) is not contained in app collection")
            guard newValue != previous else{ return }

            self.getInstance(newValue, as: AppManagerDelegatedApp.self)?.willSetCurrent(oldCurrent:self.current)
        }
        didSet {
            guard previous == nil || oldValue != current else { return }

            self.previous = oldValue

            var defaultsOfCurrent = self.currentDefaults
            defaultsOfCurrent?.touchedVersion = current?.info.version

            if let previous = self.previous, previous.info.policy.lifeCycle.instance == .availability {
                AppLifecycleManager.shared.discard(previous.info)
            }

            DispatchQueue.main.async{
                self.currentIdentifier = self.current?.info.identifier

                self.getInstance(self.current, as: AppManagerDelegatedApp.self)?.didSetCurrent(previous:self.previous)
            }
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

    private var _task = AppTaskManager.shared({ () -> UInt in
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

