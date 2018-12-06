//
// Created by BLACKGENE on 2018-10-31.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension FiltersApp: ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultFreeBAppLocalCharges
    }
}

extension TransformApp: ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultFreeBAppLocalCharges
    }
}

extension RevertApp: ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultFreeBAppLocalCharges
    }
}