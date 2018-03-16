//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol DefaultsDynamicValue {}
extension DefaultsDynamicValue where Self:Defaults{

    func set<T:Codable>(_ newValue:T?=nil, or:T, _function:String=#function){
        set(newValue ?? or, for: Key<T>(_function))
    }
    func get<T:Codable>(or:T?=nil, _function:String=#function) -> T?{
        // value is available
        if let gotValue = get(for: Key<T>(_function)){
            return gotValue
        }
        // persists default value and return
        if let gotOr = or{
            set(nil, or:gotOr,_function:_function) // set to guarantee
            return gotOr
        }
        // no value + no pre-defined default value
        return nil
    }

    func set(_ newValue:String?=nil, _function:String=#function){
        set(newValue, or:String())
    }
    func set(_ newValue:Int?=nil, _function:String=#function){
        set(newValue, or:Int())
    }
    func set(_ newValue:Bool?=nil, _function:String=#function){
        set(newValue, or:Bool())
    }
    func set(_ newValue:Float?=nil, _function:String=#function){
        set(newValue, or:Float())
    }
    func set(_ newValue:Double?=nil, _function:String=#function){
        set(newValue, or:Double())
    }
    func set(_ newValue:Date?=nil, _function:String=#function){
        set(newValue, or:Date())
    }
}

