//
// Created by BLACKGENE on 22/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct BatchAppQuery:OptionSet, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public var hashValue: Int{
        return rawValue.hashValue
    }

    public static let develop = BatchAppQuery(rawValue: 1 << 0)
    public static let beta = BatchAppQuery(rawValue: 1 << 1)
    public static let release = BatchAppQuery(rawValue: 1 << 2)

    public static func ==(lhs: BatchAppQuery, rhs: BatchAppQuery) -> Bool{
        return lhs.hashValue==rhs.hashValue
    }
}

extension BatchAppQuery{
    fileprivate static let phases:[BatchAppQuery:AppProductPhase] = [
        .develop:.develop,
        .beta:.beta,
        .release:.release,
    ]
}

public final class BatchAppCenter: NSObject, KeyPathWatchable, _SelectableCollection{
    typealias Element = App.Type

    public static let `default` = BatchAppCenter()
    override init(){
        super.init()

        TransformApp.configure = {
            let config = TransformAppConfig()
            config.tintColor = .black
            return config
        }
    }

    private(set) public var previous: App.Type?
    public var previousIndex: Int? {
        return _apps.index { previous == $0 }
    }

    public var current: App.Type? {
        didSet {
            guard oldValue != current else{ return }

            self.previous = oldValue

            self.currentName = current?.info.displayName

            if let previous = self.previous, previous.info.policy.lifeCycleUnit != AppLifecycleUnit.permanent{
                AppLifecycleManager.shared.discard(previous.info)
            }
        }
    }

    @objc dynamic
    public var currentName: String?

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

    func reset() {
        self.current = nil
        self.previous = nil
    }

    private let _apps:[App.Type] = [
        TransformApp.self,
        RevertApp.self
    ]

    /*
        apps(), apps(nil)   -> all
        apps(by: query)     -> queried
    */
    public func apps(by query: BatchAppQuery?=nil) -> [App.Type]{
        return query == nil ? self._apps : self._apps.filter { app in
            guard let query = query else{ return false }

            //productPhase
            if let _ = BatchAppQuery.phases.filter({ query.contains($0.key) }).first(where: { app.info.phase == $0.value }) {
                return true
            }

            return false
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

