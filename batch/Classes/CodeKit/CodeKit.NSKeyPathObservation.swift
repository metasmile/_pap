//
// Created by BLACKGENE on 05/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol _KeyPathWatchable:class {
    associatedtype KeyPathRoot:NSObject

    func watch<Value>(_ target:KeyPathRoot, _ keyPath:KeyPath<KeyPathRoot,Value>
            , changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> NSKeyValueObservation

    func watch<Value>(_ target:KeyPathRoot, _ keyPath:KeyPath<KeyPathRoot,Value>
            , options: NSKeyValueObservingOptions?
            , changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> NSKeyValueObservation

}

public class KeyPathWatcher<KeyPathRoot:NSObject>: NSObject, _KeyPathWatchable {
    fileprivate lazy var _observations = [NSKeyValueObservation:AnyKeyPath]()

    @discardableResult
    public func watch<Value>(_ target:KeyPathRoot, _ keyPath:KeyPath<KeyPathRoot,Value>, changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> NSKeyValueObservation {
        return self.watch(target, keyPath, options:nil, changeHandler:changeHandler)
    }

    @discardableResult
    public func watch<Value>(_ target: KeyPathRoot, _ keyPath: KeyPath<KeyPathRoot, Value>, options: NSKeyValueObservingOptions?=nil, changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> NSKeyValueObservation {
        var observer:NSKeyValueObservation

        if let _options = options{
            observer = target.observe(keyPath, options:_options, changeHandler: changeHandler)
        }else{
            print(keyPath)
            observer = target.observe(keyPath, changeHandler: changeHandler)
        }

        self._observations[observer] = keyPath
        return observer
    }
}

public protocol KeyPathWatchable {
    associatedtype _Observee:NSObject
    var watcher: KeyPathWatcher<_Observee> { get }
}

extension KeyPathWatchable where _Observee == Self{
    public var watcher: KeyPathWatcher<_Observee> {
        return KeyPathWatcher<_Observee>()
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , changeHandler: @escaping (_Observee, NSKeyValueObservedChange<Value>) -> Void) -> NSKeyValueObservation{

        return self.watcher.watch(self, keyPath, changeHandler: changeHandler)
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , options: NSKeyValueObservingOptions?=nil
            , changeHandler: @escaping (_Observee, NSKeyValueObservedChange<Value>) -> Void) -> NSKeyValueObservation{

        return self.watcher.watch(self, keyPath, options:options, changeHandler: changeHandler)
    }

    public func unwatch<Value>(_ keyPath:KeyPath<_Observee,Value>) -> Bool{
        var unwatched = false
        for (observer, keypath) in self.watcher._observations{
            if keyPath==keypath{
                self.watcher._observations.removeValue(forKey: observer)
                unwatched = true
            }
        }
        return unwatched
    }

    public func unwatchAll() {
        for observer in self.watcher._observations.keys{
            observer.invalidate()
        }
        self.watcher._observations.removeAll()
    }
}

