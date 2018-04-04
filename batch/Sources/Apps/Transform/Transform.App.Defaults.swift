//
// Created by BLACKGENE on 23/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

public protocol TransformAppDefaults: AppDefaults{
    var transform:Int? {set get}
}

extension Defaults: TransformAppDefaults {
    public var transform: Int? {
        set{ set(newValue) } get{ return get() }
    }
}