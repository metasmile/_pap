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

open class AppManager: NSObject, SelectableCollection {

    override init(){
        super.init()

        if let conf = (self as? AppManagerConfigurable)?.configure() {

            if let appCollection = conf.appCollection{
                _apps.append(contentsOf: appCollection)
            }

            if let taskManager = conf.taskManager{
                _task = taskManager
            }
        }
    }

    private var _apps = [App.Type]()

    private(set) public var previous: App.Type?
    public var previousIndex: Int? {
        return _apps.index { previous == $0 }
    }

    @objc dynamic
    public var currentIdentifier: String?

    public var current: App.Type? {
        didSet {
            guard oldValue != current else{ return }

            self.previous = oldValue

            self.currentIdentifier = current?.info.identifier

            if let previous = self.previous, previous.info.policy.lifeCycleUnit != AppLifecycleUnit.permanent{
                AppLifecycleManager.shared.discard(previous.info)
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

    public func currentInstanceAs<T>(_ protocol:T.Type) -> T?{
        guard let current = current else { return nil }
        return AppLifecycleManager.shared.acquire(current.info) as? T
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

    // Task
    public var task:AppTaskManager{
        return _task
    }

    //TODO: make AppTaskLoad, AppTaskLoadBalancer, ordering to dynamically adjust via current system condition.
    public var _task = AppTaskManager.shared({ () -> UInt in
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
        case 4:
            return 3

        case ..<4 where remainingMem>1000:
            return 3

        case ..<4:
            return 2

        default:
            return 1
        }
    }())
}

