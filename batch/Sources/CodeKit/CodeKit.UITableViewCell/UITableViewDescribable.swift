//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol UITableViewCellDefaultDescribable:
        UITableViewCellDescribable, UITableViewCellAppearanceDescribable, UITableViewCellValueDescribable {}

public protocol UITableViewCellDescribable {
    var cellIdentifier:String{get}
    var cellClass:Swift.AnyClass{get}

    var localIdentifier:Int {set get}
}

extension UITableViewCellDescribable {
    public var cellIdentifier:String{
        return String(describing: type(of: self.cellClass))
    }
}

public protocol UITableViewCellAppearanceDescribable {
    var label:String {set get}
    var iconImage:ImageSourceable? {set get}
}

public protocol UITableViewCellValueDescribable {
    var valueGetter:(() -> Any)? {set get}
    var valueCollection:Any? {set get}
    var valueHandler:((Any) -> ())? {set get}
}

public protocol UITableViewCellAccessoryDescribable {
    var transformValueLabel: ((Any) -> (String))? {get}
}

public class UITableViewCellDescriber: UITableViewCellDefaultDescribable {

    public var cellClass:Swift.AnyClass { return UITableViewCell.self }

    public var localIdentifier:Int = Int.max

    public var label: String = "Untitled"
    public var iconImage: ImageSourceable?

    public var valueGetter: (() -> Any)?
    public var valueCollection: Any?
    public var valueHandler: ((Any) -> ())?
}

public class UITableViewPickerCellDescriber: UITableViewCellDescriber {
    public override var cellClass:Swift.AnyClass { return UITableViewPickerCell.self }
}

public class UITableViewSwitchCellDescriber: UITableViewCellDescriber {
    public override var cellClass:Swift.AnyClass { return UITableViewSwitchCell.self }
}

public class UITableViewSegmentControlCellDescriber: UITableViewCellDescriber {
    public override var cellClass:Swift.AnyClass { return UITableViewSegmentedControlCell.self }
}

public class UITableViewStepperCellDescriber: UITableViewCellDescriber, UITableViewCellAccessoryDescribable {
    public override var cellClass:Swift.AnyClass { return UITableViewStepperCell.self }

//    var isContinuous: Bool = true // if YES, value change events are sent any time the value changes during interaction. default = YES
//
//    var autorepeat: Bool = true // if YES, press & hold repeatedly alters value. default = YES
//
//    var wraps: Bool = false // if YES, value wraps from min <-> max. default = NO
//
//    var value: Double // default is 0. sends UIControlEventValueChanged. clamped to min/max

    public var minimumValue: Double = 0 // default 0. must be less than maximumValue

    public var maximumValue: Double = 100 // default 100. must be greater than minimumValue

    public var stepValue: Double = 1 // default 1. must be greater than 0

    public var transformValueLabel: ((Any) -> (String))?

    public class var percentageValueTransformer:((Any) -> (String)) {
        return { value in
            var label:String?
            if let val = value as? Double{
                label = String(Int(val))
            }
            if let val = value as? Int{
                label = String(val)
            }
            return (label ?? "-")+"%"
        }
    }
}