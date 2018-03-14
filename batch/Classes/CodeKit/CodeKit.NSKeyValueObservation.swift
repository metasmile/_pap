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
            , options: NSKeyValueObservingOptions?
            , changeHandler: @escaping (KeyPathRoot, NSKeyValueObservedChange<Value>) -> Void) -> KeyPathWatcherInfo

}

public class KeyPathWatcher<KeyPathRoot:NSObject>: Object, _KeyPathWatchable {
    fileprivate lazy var _observations = [String:KeyPathWatcherInfo]()
    fileprivate lazy var _autoObservationIdsInFile = [String:[String]]() // [file : observationId]

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

    fileprivate func issueAutoIdentifier(file:String, function:String, line:Int) -> String{
        let className = file.asURL?.deletingPathExtension().lastPathComponent ?? String(describing: type(of:self))
        let autoObservationId = "\(className)_\(function)_\(String(line))"

        var idsInFile:[String]
        if let _idsInFile = _autoObservationIdsInFile[file] {
            idsInFile = _idsInFile
        }else{
            idsInFile = [String]()
            _autoObservationIdsInFile[file] = idsInFile
        }

        idsInFile.append(autoObservationId)
        return autoObservationId
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
            , _file:String=#file
            , _function:String=#function
            , _line:Int=#line
            , id:String?=nil
            , options: NSKeyValueObservingOptions?=nil
            , changeHandler: @escaping (_Observee, NSKeyValueObservedChange<Value>) -> Void
            ) -> KeyPathWatcherInfo{

        return self.watcher.watch(self, keyPath, id:id ?? self.watcher.issueAutoIdentifier(file: _file, function: _function, line: _line), options:options, changeHandler: changeHandler)
    }

    @discardableResult
    public func watch<Value>(_ keyPath:KeyPath<_Observee,Value>
            , _file:String=#file
            , _function:String=#function
            , _line:Int=#line
            , id:String?=nil
            , options: NSKeyValueObservingOptions?=nil
            , changeHandler: @escaping () -> Void) -> KeyPathWatcherInfo{

        return self.watch(keyPath, id:id ?? self.watcher.issueAutoIdentifier(file: _file, function: _function, line: _line), options:options, changeHandler: { _, _ in changeHandler() })
    }

    public func watching<Value>(by keyPath:KeyPath<_Observee,Value>, id:String?=nil) -> [KeyPathWatcherInfo]{
        return self.watcher._observations.flatMap { e -> KeyPathWatcherInfo? in
            return (id == nil ? true : id==e.key) && keyPath == e.value.keyPath ? e.value : nil
        }
    }
    @discardableResult
    public func unwatchInCurrentFile(_file:String=#file) -> Bool{
        let dict = self.watcher._autoObservationIdsInFile
        if let keysInFile = dict[_file]{
            self.unwatch(forIds: keysInFile)
            return true
        }
        return false
    }

    @discardableResult
    public func unwatch<Value>(_ keyPath:KeyPath<_Observee,Value>, forIds:[String]?=nil) -> Bool{
        assert(forIds == nil || Set(watcher._observations.flatMap({ key, value -> String? in key })).intersection(Set(forIds!)).count==0, "\(String(describing: forIds)) is still remaning.")

        var ids = self.watching(by:keyPath).map { e -> String in e.id }

        if let forIds = forIds{
            ids = Array(Set(ids).intersection(Set(forIds)))
        }
        return self.unwatch(forIds: ids)
    }

    @discardableResult
    public func unwatch(forIds:[String]) -> Bool{
        for id in forIds {
            self.watcher._observations[id]?.observer.invalidate()
            self.watcher._observations.removeValue(forKey: id)
        }
        return true
    }

    public func unwatchAll() {
        for item in self.watcher._observations{
            item.value.observer.invalidate()
        }
        self.watcher._observations.removeAll()
    }
}

