//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

struct AmountObject:Amount{
    let uuid:String = UUID().uuidString
    private(set) var value:Double
    init(value: Double) {
        self.value = type(of: self).validate(value: value)
    }
}

class MutableAmountObject: MutableAmount{
    lazy var uuid:String = UUID().uuidString

    private(set) var value: Double

    required init(value: Double){
        self.value = type(of: self).validate(value: value)
    }

    convenience init(amount: Amount) {
        self.init(value: amount.value)
    }

    @discardableResult
    func add(_ amount: Amount) -> Amount {
        self.value += clamp(amount.value, type(of: self).minValue, type(of: self).maxValue - value)
        return self
    }

    @discardableResult
    func subtract(_ amount: Amount) -> Amount {
        self.value -= clamp(amount.value, type(of: self).minValue, value)
        return self
    }

    @discardableResult
    func set(_ amount: Amount) -> Amount {
        self.value = clamp(amount.value, type(of: self).minValue, type(of: self).maxValue)
        return self
    }
}

