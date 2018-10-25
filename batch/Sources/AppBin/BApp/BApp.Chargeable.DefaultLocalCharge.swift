//
// Created by BLACKGENE on 8/24/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ChargeableApp where Self:BApp{
    static var defaultFreeBAppLocalCharges: [Charge] {
        return [
            AppCharge.createLocalAppCharge(of: self, as: .none)
        ].compactMap { $0 }
    }

    static var defaultNonConsumablePaidBAppLocalCharges: [Charge] {
        return [
            AppCharge.createLocalAppCharge(of: self, as: .nonConsumablePurchaseInAppStore)
        ].compactMap { $0 }
    }
}