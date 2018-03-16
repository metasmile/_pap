//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol DefaultsDynamicValue {}
extension DefaultsDynamicValue where Self:Defaults{
    
    func set<T:Codable>(_ newValue:T?=nil, or:T, _function:String=#function){
        set(newValue ?? or, _function:_function)
    }
    func set<T:Codable>(_ newValue:T?=nil, _function:String=#function){
        if let newValue = newValue{
            set(newValue, for: Key<T>(_function))
        }else{
            clear(Key<T>(_function))
        }
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
    func get<T:Codable>(or:T, _function:String=#function) -> T{
        return self.get(or:nil, _function:_function) ?? or
    }
}

