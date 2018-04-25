//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//TODO: Commonize ALL type of cells later later later.

public protocol UITableViewDescribable {
    var identifier:String{get}
    var cellClass:Swift.AnyClass{get}
}

extension UITableViewDescribable{
    public var identifier:String{
        return String(describing: type(of: self.cellClass))
    }
}

public struct UITableViewPickerCellDescriber: UITableViewDescribable {
    public var cellClass:Swift.AnyClass
}

public struct UITableViewSwitchCellDescriber: UITableViewDescribable {
    public var cellClass:Swift.AnyClass
}

public struct UITableViewSegmentControlCellDescriber: UITableViewDescribable {
    public var cellClass:Swift.AnyClass
}

public struct UITableViewStepperCellDescriber: UITableViewDescribable {
    public var cellClass:Swift.AnyClass

//    var isContinuous: Bool = true // if YES, value change events are sent any time the value changes during interaction. default = YES
//
//    var autorepeat: Bool = true // if YES, press & hold repeatedly alters value. default = YES
//
//    var wraps: Bool = false // if YES, value wraps from min <-> max. default = NO
//
//    var value: Double // default is 0. sends UIControlEventValueChanged. clamped to min/max

    var minimumValue: Double = 0 // default 0. must be less than maximumValue

    var maximumValue: Double = 100 // default 100. must be greater than minimumValue

    var stepValue: Double = 1 // default 1. must be greater than 0
}