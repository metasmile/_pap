//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct BatchAppCenterNotification {
    enum Name {
        static let didChangeCurrent = Notification.Name("BatchAppCenterNotification.didChangeCurrent")
    }

    struct UserInfo {
        enum Key {
            static let previous = "previous"
        }
    }
}

public struct BatchAppQuery {
    let state:AppState
}


public final class BatchAppCenter: NSObject, KeyPathWatchable, _SelectableCollection{
    typealias Element = App.Type
    public static let `default` = BatchAppCenter()

    private(set) public var previous: App.Type?
    public var previousIndex: Int? {
        return apps.index { previous == $0 }
    }

    public var current: App.Type? {
        didSet {
            self.previous = oldValue
            self.currentName = current?.info.displayName
            print(self.currentName)

            if let previous = self.previous, previous.info.policy.lifeCycleUnit != AppLifecycleUnit.permanent{
                AppLifecycleManager.shared.discard(previous.info)
            }

            NotificationCenter.default.post(name: BatchAppCenterNotification.Name.didChangeCurrent, object: self)
        }
    }

    @objc dynamic
    public var currentName: String?

    public var currentIndex: Int? {
        get {
            return apps.index { current == $0 }
        }
        set {
            if let index = newValue, apps.indices.contains(index) {
                current = apps[index]
            }else{
                current = nil
            }
        }
    }

    public func currentInstanceAs<T>(_ protocol:T.Type) -> T?{
        guard let current = current else { return nil }
        return AppLifecycleManager.shared.acquire(current.info) as? T
    }

    func reset() {
        self.current = nil
        self.previous = nil
    }

    public let apps:[App.Type] = [
        TransformApp.self,
        RevertApp.self
    ]

    public func apps(by query: BatchAppQuery) -> [App.Type]?{
        return self.apps.filter { app in
            return app.info.state == query.state
        }
    }


    // Task
    //TODO: make AppTaskLoad, AppTaskLoadBalancer, ordering to dynamically adjust via current system condition.
    public let task = AppTaskManager.shared({ () -> UInt in
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

