//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

protocol ConverterAppDefaults: AppDefaults{
    var convertingDirection: ConvertingDirection {get set}
    var convertingQuality: ConvertingQuality {get set}
}

extension Defaults: ConverterAppDefaults {
    var convertingDirection: ConvertingDirection {
        set { set(newValue) }
        get { return get(or: ConvertingDirection(from: .mov, to: .livephoto)) }
    }
    
    var convertingQuality: ConvertingQuality {
        set { set(newValue, for: Key("convertingQualityFor_\(newValue.convertingDirection.identifier)")) }
        get { return get(for: Key("convertingQualityFor_\(convertingDirection.identifier)")) ?? ConvertingQuality(convertingDirection: convertingDirection, qualityType: .high) }
    }
}
