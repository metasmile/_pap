//
// Created by BLACKGENE on 8/14/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import StoreKit
import DefaultsKit

protocol StorePayable: VerifiablePayable {
    static var product: StoreProduct {get}

    static var storeProduct:SKProduct? {get}

    static func fetchStoreProduct(_ signal:AsyncWaitSignalable) -> Bool
}

struct StoreProduct {
    let identifier:String
    let subscriptionPeriod: Period?
}
