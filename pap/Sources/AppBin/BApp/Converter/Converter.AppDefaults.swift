//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import PropertyKit

protocol ConverterAppDefaults: AppDefaults{
    var convertingDirection: ConvertingDirection {get set}
    var convertingQuality: ConvertingQuality {get set}
}

extension Defaults: ConverterAppDefaults {
    var convertingDirection: ConvertingDirection {
        set { set(newValue); papLog.app.defaults.log(value:newValue.identifier) }
        get { return get(or: ConvertingDirection(from: .livephoto, to: .gif)) }
    }
    
    var convertingQuality: ConvertingQuality {
        set { set(newValue, key:"convertingQualityFor_\(newValue.convertingDirection.identifier)") }
        get { return get(key:"convertingQualityFor_\(convertingDirection.identifier)") ?? ConvertingQuality(convertingDirection: convertingDirection, qualityType: .high) }
    }
}
