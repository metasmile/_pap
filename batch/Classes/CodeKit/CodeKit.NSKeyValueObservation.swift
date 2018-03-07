//
// Created by BLACKGENE on 05/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct KeyPathWatcherInfo{
    public static let StaticId="\(KeyPathWatcherInfo.self)_staticWatchId"

    var id:String
    var observer:NSKeyValueObservation
    var keyPath:AnyKeyPath
}

public protocol _KeyPathWatchable:class {
    associatedtype KeyPathRoot:NSObject

    func watch<Value>(_ target:KeyPathRoot, _ keyPath:KeyPath<KeyPathRoot,Value>
            , id:String
            , changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo

    func watch<Value>(_ target:KeyPathRoot, _ keyPath:KeyPath<KeyPathRoot,Value>
            , id:String
            , options: NSKeyValueObservingOptions?
            , changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo

}

public class KeyPathWatcher<KeyPathRoot:NSObject>: Object, _KeyPathWatchable {
    fileprivate lazy var _observations = [String:KeyPathWatcherInfo]()

    @discardableResult
    public func watch<Value>(_ target:KeyPathRoot
            , _ keyPath:KeyPath<KeyPathRoot,Value>
            , id:String
            , changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo {

        return self.watch(target, keyPath, id:id, options:nil, changeHandler:changeHandler)
    }

    @discardableResult
    public func watch<Value>(_ target: KeyPathRoot
            , _ keyPath: KeyPath<KeyPathRoot, Value>
            , id:String
            , options: NSKeyValueObservingOptions?=nil
            , changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo {

        if let existedInfo = _observations[id]{
            existedInfo.observer.invalidate()
            _observations.removeValue(forKey: id)
        }

        var observer:NSKeyValueObservation

        if let _options = options{
            observer = target.observe(keyPath, options:_options, changeHandler: changeHandler)
        }else{
            observer = target.observe(keyPath, changeHandler: changeHandler)
        }
        let info = KeyPathWatcherInfo(id:id, observer: observer, keyPath: keyPath)
        self._observations[id] = info

        return info
    }
}

public protocol KeyPathWatchable {
    associatedtype _Observee:NSObject
    var watcher: KeyPathWatcher<_Observee> {get}
}

private struct KeyPathWatchableAssociatedKeys {
    static var watcher:Int?
}

extension KeyPathWatchable where _Observee == Self{
    public var watcher: KeyPathWatcher<_Observee> {
        var _watcher = objc_getAssociatedObject(self, &KeyPathWatchableAssociatedKeys.watcher)
        if _watcher == nil {
            _watcher = KeyPathWatcher<_Observee>()
            objc_setAssociatedObject(self, &KeyPathWatchableAssociatedKeys.watcher, _watcher, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return _watcher as! KeyPathWatcher<_Observee>
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , id:String?=nil
            , options: NSKeyValueObservingOptions?=nil
            , changeHandler: @escaping (_Observee, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo{

        return self.watcher.watch(self, keyPath, id:id ?? KeyPathWatcherInfo.StaticId, options:options, changeHandler: changeHandler)
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , id:String?=nil
            , options: NSKeyValueObservingOptions?=nil
            , changeHandler: @escaping () -> Void) -> KeyPathWatcherInfo{

        return self.watch(keyPath, id:id, options:options, changeHandler: { _,_ in changeHandler() })
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , id:String?=nil
            , changeHandler: @escaping (_Observee, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo{

        return self.watcher.watch(self, keyPath, id:id ?? KeyPathWatcherInfo.StaticId, changeHandler: changeHandler)
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , id:String?=nil
            , changeHandler: @escaping () -> Void) -> KeyPathWatcherInfo{

        return self.watch( keyPath, id:id, changeHandler: { _,_ in changeHandler() })
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , changeHandler: @escaping (_Observee, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo{

        return self.watch(keyPath, id:nil, changeHandler: changeHandler)
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , changeHandler: @escaping () -> Void) -> KeyPathWatcherInfo{

        return self.watch(keyPath, id:nil, changeHandler: changeHandler)
    }

    public func watching<Value>(by keyPath:KeyPath<_Observee,Value>, id:String?=nil) -> [KeyPathWatcherInfo]{
        return self.watcher._observations.flatMap { e -> KeyPathWatcherInfo? in
            return (id == nil ? true : id==e.key) && keyPath == e.value.keyPath ? e.value : nil
        }
    }

    @discardableResult
    public func unwatch<Value>(_ keyPath:KeyPath<_Observee,Value>, forIds:[String]?=nil) -> Bool{
        var ids = self.watching(by:keyPath).map { e -> String in e.id }

        if let forIds = forIds{
            ids = Array(Set(ids).intersection(Set(forIds)))
        }

        for id in ids {
            self.watcher._observations.removeValue(forKey: id)
        }

        assert(forIds == nil || Set(watcher._observations.flatMap({ key, value -> String? in key })).intersection(Set(forIds!)).count==0, "\(forIds) is still remaning.")
        return true
    }

    public func unwatchAll() {
        for item in self.watcher._observations{
            item.value.observer.invalidate()
        }
        self.watcher._observations.removeAll()
    }
}

