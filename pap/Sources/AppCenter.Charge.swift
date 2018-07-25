//
// Created by BLACKGENE on 24.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

struct AppChargeableItem: Chargeable{
    var type: ChargeType
    var reward: RewardType
}

private struct AppChargeItem: Charge {
    var type: ChargeType
    var reward: RewardType

    let price:Double
    let title: String
    let description: String?
}

extension AppCenter{
    static let chargeManager:ChargeManager = papChargeManager(charges:[
        AppChargeItem(type: .inStoreRating, reward: .timeOfUses,  price: 0.5, title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .onPromptRating, reward: .timeOfUses, price: 0.3, title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .socialShare, reward: .timeOfUses, price: 0.2, title:"AppStore Rating", description:nil)
        , AppChargeItem(type: .feedback, reward: .timeOfUses, price: 1, title:"AppStore Rating", description:nil)
        /* .... */
    ])
}

private final class papChargeManager: ChargeManager{
    //TODO: pap specific overridden policies here
    override init(charges: [Charge]) {
        super.init(charges: charges)

        self.resetBalance()
    }
}