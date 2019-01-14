//
// Created by BLACKGENE on 2018-10-31.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension ExifGhostApp: ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultNonConsumablePaidBAppLocalCharges
    }
}

extension CleanerApp: ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultNonConsumablePaidBAppLocalCharges
    }
}

extension ArtistApp:ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultNonConsumablePaidBAppLocalCharges
    }
}

extension FinderApp:ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultNonConsumablePaidBAppLocalCharges
    }
}

extension MemoCamApp:ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultNonConsumablePaidBAppLocalCharges
    }
}

extension RawEditorApp:ChargeableApp{
    static var localCharges: [Charge] {
        return self.defaultNonConsumablePaidBAppLocalCharges
    }
}