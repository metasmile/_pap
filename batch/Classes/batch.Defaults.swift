//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

extension Defaults: DefaultsDynamicValue {
    public var appBundleIdentifier: String? {
        set(newValue){ set_String(newValue) } get{ return get_String() }
    }
}

