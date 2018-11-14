//
// Created by BLACKGENE on 8/14/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import StoreKit


extension SKProduct {

    var localizedPrice: String? {
        return type(of: self).localizePrice(price: price, locale:priceLocale)
    }

    static func localizePrice(price:NSDecimalNumber, locale:Locale) -> String?{
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: price)
    }

}