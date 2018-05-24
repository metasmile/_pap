//
// Created by BLACKGENE on 15/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

extension Defaults: DefaultsAutoProperty {
    public var appIdentifier: String? {
        set{ set(newValue) } get{ return get() }
    }

    public var appDockContentLayoutState: Int {
        set{ set(newValue) } get{ return get(or:AppDockContentLayoutState.neutralized.rawValue) }
    }
}

