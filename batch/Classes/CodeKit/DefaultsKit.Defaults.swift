//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol DefaultsDynamicValue {}
extension DefaultsDynamicValue where Self:Defaults{
    // Swift Codable
    func get_String(_function:String=#function) -> String?{
        return get(for: Key<String>(_function))
    }
    func set_String(_ newValue:String?, defaultValue:String?=nil, _function:String=#function){
        set(newValue ?? (defaultValue ?? String()), for: Key<String>(_function))
    }

    func get_Int(_function:String=#function) -> Int?{
        return get(for: Key<Int>(_function))
    }
    func set_Int(_ newValue:Int?, defaultValue:Int?=nil, _function:String=#function){
        set(newValue ?? (defaultValue ?? Int()), for: Key<Int>(_function))
    }

    func get_Float(_function:String=#function) -> Float?{
        return get(for: Key<Float>(_function))
    }
    func set_Float(_ newValue:Float?, defaultValue:Float?=nil, _function:String=#function){
        set(newValue ?? (defaultValue ?? Float()), for: Key<Float>(_function))
    }

    func get_Double(_function:String=#function) -> Double?{
        return get(for: Key<Double>(_function))
    }
    func set_Double(_ newValue:Double?, defaultValue:Double?=nil, _function:String=#function){
        set(newValue ?? (defaultValue ?? Double()), for: Key<Double>(_function))
    }

    func get_Bool(_function:String=#function) -> Bool?{
        return get(for: Key<Bool>(_function))
    }
    func set_Bool(_ newValue:Bool?, defaultValue:Bool?=nil, _function:String=#function){
        set(newValue ?? false, for: Key<Bool>(_function))
    }

    // Swift Foundation
    func get_Date(_function:String=#function) -> Date?{
        return get(for: Key<Date>(_function))
    }
    func set_Date(_ newValue:Date?, defaultValue:Date?=nil, _function:String=#function){
        set(newValue ?? (defaultValue ?? Date()), for: Key<Date>(_function))
    }
}

