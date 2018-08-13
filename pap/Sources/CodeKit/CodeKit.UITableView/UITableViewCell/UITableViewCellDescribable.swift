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

    var itemIdentifier:Int {set get}
}

extension UITableViewCellDescribable {
    public var cellIdentifier:String{
        return String(describing: type(of: self.cellClass))
    }
}

public protocol UITableViewCellAppearanceDescribable {
    var label:String {set get}
    var detailedLabel:String? {set get}
    var iconImage:ImageSourceable? {set get}
}

public protocol UITableViewCellValueDescribable {
    var valueGetter:() -> Any? {set get}
    var valueHandler:((Any) -> ())? {set get}
}

public protocol UITableViewCellMultipleValueDescribable {
    var valueCollection: Any? {set get}
}

public protocol UITableViewCellAccessoryDescribable {
    var valuePresenter: ((Any) -> (String))? {get}
}

extension UITableViewCellAccessoryDescribable where Self:UITableViewCellValueDescribable{
    public var presentableValue: String? {
        if let value = self.valueGetter(){
            return valuePresenter?(value) ?? value as? String
        }
        return nil
    }
}

extension UITableViewCellAccessoryDescribable{
    public static var percentageAsIntValuePresenter:((Any) -> (String)) {
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

public class UITableViewCellDescriber: UITableViewCellDefaultDescribable {

    public var cellClass:Swift.AnyClass { return UITableViewCell.self }

    public lazy var itemIdentifier:Int = Int.max

    public var label: String = "Untitled"
    public var detailedLabel:String?
    public var iconImage: ImageSourceable?

    public var valueGetter: () -> Any? = { nil }
    public var valueHandler: ((Any) -> ())?

    convenience public init(label:String, iconImage:ImageSourceable?=nil){
        self.init()
        self.label = label
        self.iconImage = iconImage
    }
}

public class UITableViewButtonCellDescriber: UITableViewCellDescriber {
    public override var cellClass:Swift.AnyClass { return UITableViewButtonCell.self }

    public var buttonImage:ImageSourceable?
    public var buttonTitleLabel:String?
}

public class UITableViewPickerCellDescriber: UITableViewCellDescriber, UITableViewCellMultipleValueDescribable {
    public override var cellClass:Swift.AnyClass { return UITableViewPickerCell.self }

    public var valueCollection: Any?
}

public class UITableViewMultiplePickerCellDescriber: UITableViewCellDescriber, UITableViewCellMultipleValueDescribable {
    public override var cellClass:Swift.AnyClass { return UITableViewMultiplePickerCell.self }
    
    public var valueCollection: Any?
}

public class UITableViewSwitchCellDescriber: UITableViewCellDescriber {
    public override var cellClass:Swift.AnyClass { return UITableViewSwitchCell.self }
}

public class UITableViewSwitchSubtitleCellDescriber: UITableViewSwitchCellDescriber {
    public override var cellClass:Swift.AnyClass { return UITableViewSwitchSubtitleCell.self }
}

public class UITableViewSegmentControlCellDescriber: UITableViewCellDescriber, UITableViewCellMultipleValueDescribable {
    public override var cellClass:Swift.AnyClass { return UITableViewSegmentedControlCell.self }

    public var valueCollection: Any?
}

public class UITableViewSimpleValueCellDescriber: UITableViewCellDescriber, UITableViewCellAccessoryDescribable {
    public override var cellClass:Swift.AnyClass { return UITableViewSimpleValueCell.self }

    public var valuePresenter: ((Any) -> (String))?
}

public class UITableViewActionSheetCellDescriber: UITableViewCellDescriber, UITableViewCellMultipleValueDescribable, UITableViewCellAccessoryDescribable {
    public override var cellClass:Swift.AnyClass { return UITableViewActionSheetCell.self }

    public var valueCollection: Any?

    public var valuePresenter: ((Any) -> (String))?
}

public class UITableViewStepperCellDescriber: UITableViewCellDescriber, UITableViewCellMultipleValueDescribable, UITableViewCellAccessoryDescribable {
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

    public var valueCollection: Any?

    public var valuePresenter: ((Any) -> (String))?
}
