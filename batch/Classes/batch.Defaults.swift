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
    public var appBundleIdentifier: String? {
        set(newValue){ set(newValue) } get{ return get() }
    }

    public var testInt: Int? {
        set(newValue){ set(newValue) } get{ return get() }
    }

    public var testDate: Date? {
        set(newValue){ set(newValue) } get{ return get() }
    }

    public var testCustom: CustomStruct? {
        set(newValue){ set(newValue, defaultValue:CustomStruct()) } get{ return get() }
    }
}

