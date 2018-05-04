//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol ConverterAppDefaults: AppDefaults{
    var convertingDirection: ConvertableDirection {get set}
}

extension Defaults: ConverterAppDefaults {
    var convertingDirection: ConvertableDirection {
        set { set(newValue) }
        get { return get(or:ConvertableDirection(from: .video, to: .livephoto)) }
    }
}
