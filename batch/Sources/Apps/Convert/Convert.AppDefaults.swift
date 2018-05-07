//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol ConvertAppDefaults: AppDefaults{
    var convertingDirection: ConvertableDirection {get set}
}

extension Defaults: ConvertAppDefaults {
    var convertingDirection: ConvertableDirection {
        set { set(newValue) }
        get { return get(or:ConvertableDirection(from: .mov, to: .livephoto)) }
    }
}
