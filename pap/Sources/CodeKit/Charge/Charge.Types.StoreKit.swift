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

/*
    Action
*/
extension StorePayable where Self:TrialablePayable{
    static var action:PayableAction {
        if self.isAvailableToStartTutorial {
            return PayableAction(title:"Start Tutorial".localized, detailedTitle: trialTimeLengthLocalizedDayString)
        }
        return defaultStoreAction
    }
}

extension StorePayable {
    static var action:PayableAction {
        return defaultStoreAction
    }

    static var defaultStoreAction:PayableAction{
        return cachedStorePricingAction ?? PayableAction(title: "Purchase".localized)
    }
    
    fileprivate static var cachedStorePricingAction:PayableAction?{
        var str:PayableAction?

        if let storeProduct = storeProduct {
            let priceString = storeProduct.localizedPrice ?? String(describing: storeProduct.price)

            //INFO: Per Day Display
            if let subscriptionPeriod = product.subscriptionPeriod{
                let priceValue = storeProduct.price.doubleValue
                let unitAmount = subscriptionPeriod.numberOfUnits
                let perDayPriceValue:Double
                switch subscriptionPeriod.unit {
                case .day:
                    perDayPriceValue = priceValue/unitAmount
                case .week:
                    perDayPriceValue = priceValue/(7*unitAmount)
                case .month:
                    perDayPriceValue = priceValue/(30.436875*unitAmount)
                case .year:
                    perDayPriceValue = priceValue/(365*unitAmount)
                default:
                    perDayPriceValue = 0
                }

                if let pricePerDayString = SKProduct.localizePrice(price: NSDecimalNumber(value: perDayPriceValue.round(toPlaces: 2)), locale: storeProduct.priceLocale){
                    str = PayableAction(title: priceString, detailedTitle: "%@/Day".localizedFormatted(pricePerDayString))
                }

            }else{
                str = PayableAction(title: priceString)
            }
        }

        if let str = str {
            Defaults.shared.cachedStorePayableActions[product.identifier] = str
        }

        return str ?? Defaults.shared.cachedStorePayableActions[product.identifier]
    }
}

private protocol StorePayablePrivateDefaults: AppDefaults{
    var cachedStorePayableActions:[String: PayableAction] {get set}
}

extension Defaults: StorePayablePrivateDefaults {
    fileprivate var cachedStorePayableActions: [String: PayableAction] {
        set{ set(newValue) }
        get{ return get(or:[String: PayableAction]()) }
    }
}
