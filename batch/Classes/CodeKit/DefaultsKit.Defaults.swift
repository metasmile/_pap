//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

/*
    DefaultsAutoProperty protocol extension, Added by Taeho Lee (github.com/metasmile)

    An example to use:

    public struct CustomValueType: Codable{
        var key:String = "value"
    }

    extension Defaults: DefaultsAutoProperty {
        public var autoStringProperty: String? {
            set(newValue){ set(newValue) } get{ return get() }
        }

        public var autoDateProperty: Date? {
            set(newValue){ set(newValue) } get{ return get() }
        }

        public var autoStringPropertyWithDefaultValue: String? {
            set(newValue){ set(newValue) } get{ return get(or:"default string value") }
        }

        public var autoCustomNonOptionalProperty: CustomValueType {
            set(newValue){ set(newValue) } get{ return get(or: CustomValueType()) }
        }

        public var autoCustomOptionalProperty: CustomValueType? {
            set(newValue){ set(newValue, or: CustomValueType()) } get{ return get() }
        }
    }

    Result:

    Defaults.shared.autoStringProperty = "new value will persist"

*/

protocol DefaultsAutoProperty {}
extension DefaultsAutoProperty where Self:Defaults{

    /// Sets a newValue automatically associated with the current function(key) name.
    /// If newValue is nil, the key in UserDefaults will be deleted.
    ///
    /// - Parameters:
    ///   - newValue: The value to set.
    ///   - or: default value. Non-Optional.
    ///   - key: private key name. it will set automatically via #function macro.
    func set<T:Codable>(_ newValue:T?=nil, or:T, key:String=#function){
        set(newValue ?? or, key: key)
    }
    // Alias set function:
    func set<T:Codable>(_ newValue:T?=nil, key:String=#function){
        if let newValue = newValue{
            set(newValue, for: Key<T>(key))
        }else{
            clear(Key<T>(key))
        }
    }

    /// Returns the value or default value associated with the specified key.
    ///
    /// - Parameter 
    ///   - or: default value.
    ///   - key: private key name. it will set automatically via #function macro.
    /// - Returns: A `ValueType` or nil if the key was not found.
    func get<T:Codable>(or:T?=nil, key:String=#function) -> T?{
        // value is available
        if let gotValue = get(for: Key<T>(key)){
            return gotValue
        }
        // persists default value
        if let gotOr = or{
            set(nil, or:gotOr,key: key) // set to guarantee
            return gotOr
        }
        // no value + no pre-defined default value
        return nil
    }
    func get<T:Codable>(or:T, key:String=#function) -> T{
        return self.get(or:nil, key: key) ?? or
    }
}

