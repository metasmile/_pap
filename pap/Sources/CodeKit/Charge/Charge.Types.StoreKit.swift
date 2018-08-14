//
// Created by BLACKGENE on 8/14/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import StoreKit

protocol StorePayable: VerifiablePayable {
    static var product: StorePayableProduct {get}

    static var storeProduct:SKProduct? {get}

    static func fetchStoreProduct(_ signal:AsyncWaitSignalable) -> Bool
}

protocol StorePayableProduct {
    var identifier:String {get}
}

struct StoreProduct:StorePayableProduct {
    let identifier:String
}