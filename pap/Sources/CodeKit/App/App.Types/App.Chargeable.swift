//
// Created by BLACKGENE on 25.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public struct Charge {
    public let identifier: String
    public let priceAmount: AmountObject
    public let type: ChargeType
    public let reward: RewardType
    public init(identifier: String, priceAmount: AmountObject, type: ChargeType, reward: RewardType) {
        self.identifier = identifier
        self.priceAmount = priceAmount
        self.type = type
        self.reward = reward
    }
}

public enum ChargeType: Int {
    case free, paid, subscription, deprecated
}

public enum RewardType: Int {
    case consumable, nonConsumable, renewable, deprecated
    public var isNonConsumable: Bool { return self == .nonConsumable }
}

public struct AmountObject {
    public let value: Double
    public static let minValue: Double = 0
    public static let maxValue: Double = Double.greatestFiniteMagnitude
    public init(value: Double) { self.value = value }
}

protocol ChargeableApp :App{
    static var localCharges:[Charge] {get}
}