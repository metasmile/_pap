//
// Created by BLACKGENE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

struct AppChargeItem: Chargeable{
    let type: ChargeType
    let reward: RewardType
}

private struct AppChargeScheme: ChargeableScheme {
    let type: ChargeType
    let price:Double
    let reward: RewardType
    let title: String
    let description: String?
}

extension AppCenter{
    static let chargeManager:ChargeManager = papChargeManager(scheme:[
        AppChargeScheme(type: .inStoreRating, price: 0.5, reward: .timeOfUses, title:"AppStore Rating", description:nil)
        , AppChargeScheme(type: .onPromptRating, price: 0.3, reward: .timeOfUses, title:"AppStore Rating", description:nil)
        , AppChargeScheme(type: .socialShare, price: 0.2, reward: .timeOfUses, title:"AppStore Rating", description:nil)
        , AppChargeScheme(type: .feedback, price: 1, reward: .timeOfUses, title:"AppStore Rating", description:nil)
        /* .... */
    ].dictionary { (item: AppChargeScheme) -> ChargeType in
        return item.type
    })
}

private final class papChargeManager: ChargeManager{
    //TODO: pap specific overridden policies here
    override init(scheme: [ChargeType: ChargeableScheme]) {
        super.init(scheme: scheme)

//        self.resetBalance()
    }
}