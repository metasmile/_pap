//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

public struct CustomStruct: Codable{
    var customProperty:String = "dd"
}

extension Defaults: DefaultsDynamicValue {
    public var appIdentifier: String? {
        set(newValue){ set(newValue, or:TransformApp.info.identifier) } get{ return get(or:TransformApp.info.identifier) }
    }

    public var testInt: Int? {
        set(newValue){ set(newValue) } get{ return get() }
    }

    public var testDate: Date? {
        set(newValue){ set(newValue) } get{ return get() }
    }

    public var testCustom: CustomStruct? {
        set(newValue){ set(newValue, or:CustomStruct()) } get{ return get() }
    }

    public var testCustom1: CustomStruct? {
        set(newValue){ set(newValue, or:CustomStruct()) } get{ return get(or:CustomStruct()) }
    }

    public var testCustom2: CustomStruct? {
        set(newValue){ set(newValue, or:CustomStruct(customProperty:"default")) } get{ return get(or:CustomStruct()) }
    }
}

