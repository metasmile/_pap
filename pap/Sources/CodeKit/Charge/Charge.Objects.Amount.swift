//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

class AmountObject: Amount{
    static let minValue:Double = 0
    static let maxValue:Double = 1

    lazy var uuid:String = UUID().uuidString

    fileprivate(set) var value: Double = Double.nan

    required init(value: Double) {
        if value >= type(of: self).minValue && value <= type(of: self).maxValue {
            self.value = value
        }else{
            assert(false,"Amount is allowed only 0...1")
        }
    }
}

class MutableAmountObject: AmountObject, MutableAmount{
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

