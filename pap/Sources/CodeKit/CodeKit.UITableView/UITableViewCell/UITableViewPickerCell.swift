//
//  Created by Aziz Uysal on 3/23/17.
//  Copyright © 2017 Aziz Uysal. All rights reserved.

// ref: https://github.com/azizuysal/UITableViewPickerCell/blob/master/UITableViewPickerCell/UITableViewPickerCell/UITableViewPickerCell.swift
// ref readme: https://github.com/azizuysal/UITableViewPickerCell

// Modified by metasmile
// 1. rename: UITableViewPickerCell -> UITableViewPickerCell
// 2. initializer for dequeue
//

import Foundation
import UIKit

public protocol UITableViewExpandableCell {
    var isExpanded: Bool { get }
    var estimatedHeightForRowSelected: CGFloat { get }
    /**
     Expands or contracts the table cell depending on its current state. Call this method from the "tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)" delegate method to show or hide the picker view with an animation.
     - Parameter tableView: The UITableView object that contains the cell.
     */
    func expand(_ tableView: UITableView, animated:Bool, completion:((Bool) -> Swift.Void)?)
    func contract(_ tableView: UITableView, animated:Bool, completion:((Bool) -> Swift.Void)?)
    func updateForExpansion(_ tableView: UITableView, animated:Bool, completion:((Bool) -> Swift.Void)?)
}

/**
 The delegate of an UITableViewPickerCell object must adopt this protocol and implement its methods to retrieve the currently selected values.
*/
public protocol UITableViewPickerCellDelegate {
    /**
     Called by the picker view when the user selects a value.
     - Parameter cell: An object representing the table view cell that contains the picker view.
     - Parameter row: A zero-indexed number identifying a row of a component. Rows are numbered top-to-bottom. This value is ignored if the picker type is .date.
     - Parameter value: The value represented by the selected row. This is a string for .default, and a date for .date type pickers.
    */
    func pickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any)
}

public class UITableViewPickerCell: UITableViewCell, UITableViewExpandableCell {

    /**
     The picker type determines whether a UIPickerView or a UIDatePicker is used to display and pick values.
    */
    public enum PickerType {
        /// A type that displays a UIPickerView to select from provided strings.
        case `default`
        /// A type that displays a UIDatePicker to select a date and/or time.
        case date
    }

    /**
     The mode determines whether dates, times, or both dates and times are displayed. You can set and retrieve the mode value through the datePickerMode property.
    */
    public enum DatePickerMode {
        /// A mode that displays the date in months, days of the month, and years. The exact order of these items depends on the locale setting. An example of this mode is [ November | 15 | 2007 ].
        case date
        /// A mode that displays the date as unified day of the week, month, and day of the month values, plus hours, minutes, and (optionally) an AM/PM designation. The exact order and format of these items depends on the locale set. An example of this mode is [ Wed Nov 15 | 6 | 53 | PM ].
        case dateAndTime
        /// A mode that displays the date in hours, minutes, and (optionally) an AM/PM designation. The exact items shown and their order depend upon the locale set. An example of this mode is [ 6 | 53 | PM ].
        case time
    }

    /// The label on the left side of the cell that typically displays an explanatory text.
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// The label on the right side of the cell that displays the currently selected value in the picker view.
    public let valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public var defaultValueLabelTextColor = UIColor.darkText {
        didSet{
            valueLabel.textColor = defaultValueLabelTextColor
        }
    }

    private let separator: ColorLockedView = {
        let view = ColorLockedView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.lockedBackgroundColor = UIColor(white: 0, alpha: 0.1)
        return view
    }()
    private var picker: UIView = UIPickerView()

    /// The type of the picker used in the cell.
    public private(set) var pickerType = PickerType.default

    /// The current status of the cell's status. The picker view is visible while the cell is expanded and hidden when it is not. Set this property to the desired state and reload table view rows to expand or contract the cell.
    private(set) public var isExpanded = false

    private var titleLabelHeightConstraint: NSLayoutConstraint?
    private var valueLabelHeightConstraint: NSLayoutConstraint?
    private var separatorHeightConstraint: NSLayoutConstraint?

    /// The height of the cell when the it is not expanded. The default is 44.0.
    public var unexpandedHeight: CGFloat = 44.0 {
        didSet {
            titleLabelHeightConstraint?.constant = unexpandedHeight
            valueLabelHeightConstraint?.constant = unexpandedHeight
        }
    }

    /// The height (thickness) of the separator line between the labels and the picker view when the cell is expanded. The default is 0.5.
    public var separatorHeight: CGFloat = 0.5 {
        didSet {
            separatorHeightConstraint?.constant = separatorHeight
        }
    }

    // option handler
    public var didPickHandler:((_ cell: UITableViewPickerCell, _ row: Int, _ value: Any) -> ())?

    /// An array of strings to be displayed by the picker view. This is ignored if picker type is not .default.
    public var values = [String]()

    /// A class that receives notifications from an UITableViewPickerCell instance. The class must implement the required protocol method "auPickerCell(_ cell: UITableViewPickerCell, didPick row: Int, value: Any)"
    public var delegate: UITableViewPickerCellDelegate?

    /**
     The currently selected row of string picker.

     Use this property to get and set the currently selected row. The default value is 0. Setting this property animates the picker by spinning the wheels to the new value; if you don't want any animation to occur when you set the row, use the setSelectedRow(_:animated:) method, passing false for the animated parameter. This is ignored if picker type is not .default.
     */
    public var selectedRow: Int {
        get {
            return _selectedRow
        }
        set {
            setSelectedRow(newValue, animated: true)
        }
    }
    private var _selectedRow: Int = 0

    private static let dateFormatter = DateFormatter()

    /**
     The time style used to display the selected time in the right hand side label. The default is short which display a string like "9:42 AM". This is ignored if picker type is not .date.
     */
    public var timeStyle = DateFormatter.Style.short {
        didSet {
            guard let _ = picker as? UIDatePicker else {
                return
            }
            UITableViewPickerCell.dateFormatter.timeStyle = timeStyle
            valueLabel.text = UITableViewPickerCell.dateFormatter.string(from: date)
        }
    }

    /**
     The date style used to display the selected date in the right hand side label. The default is medium which display a string like "May 7, 2013". This is ignored if picker type is not .date.
    */
    public var dateStyle = DateFormatter.Style.medium {
        didSet {
            guard let _ = picker as? UIDatePicker else {
                return
            }
            UITableViewPickerCell.dateFormatter.dateStyle = dateStyle
            valueLabel.text = UITableViewPickerCell.dateFormatter.string(from: date)
        }
    }

    /**
     The time zone reflected in the date displayed by the date picker.

     The default value is nil, which tells the date picker to use the current time zone as returned by current (TimeZone) or the time zone used by the date picker’s calendar. This is ignored if picker type is not .date.
    */
    public var timeZone: TimeZone? = nil {
        didSet {
            guard let picker = picker as? UIDatePicker else {
                return
            }
            picker.timeZone = timeZone
            UITableViewPickerCell.dateFormatter.timeZone = timeZone
            valueLabel.text = UITableViewPickerCell.dateFormatter.string(from: date)
        }
    }

    /**
     The minimum date the date picker can show.

     Use this property to configure the minimum date that is selected in the date picker interface. The property contains a Date object or nil (the default), which means no minimum date. This property, along with the maximumDate property, lets you specify a valid date range. If the minimum date value is greater than the maximum date value, both properties are ignored. This is ignored if picker type is not .date.
    */
    public var minimumDate: Date? = nil {
        didSet {
            guard let picker = picker as? UIDatePicker else {
                return
            }
            picker.minimumDate = minimumDate
        }
    }

    /**
     The maximum date the date picker can show.

     Use this property to configure the maximum date that is selected in the date picker interface. The property contains a Date object or nil (the default), which means no maximum date. This property, along with the minimumDate property, lets you specify a valid date range. If the minimum date value is greater than the maximum date value, both properties are ignored. This is ignored if picker type is not .date.
    */
    public var maximumDate: Date? = nil {
        didSet {
            guard let picker = picker as? UIDatePicker else {
                return
            }
            picker.maximumDate = maximumDate
        }
    }

    /**
     The interval at which the date picker should display minutes.

     Use this property to set the interval displayed by the minutes wheel (for example, 15 minutes). The interval value must be evenly divided into 60; if it is not, the default value is used. The default and minimum values are 1; the maximum value is 30. This is ignored if picker type is not .date.
    */
    public var minuteInterval: Int = 1 {
        didSet {
            guard let picker = picker as? UIDatePicker else {
                return
            }
            picker.minuteInterval = minuteInterval
        }
    }

    /**
     The mode of the date picker.

     Use this property to change the type of information displayed by the date picker. It determines whether the date picker allows selection of a date, a time, or both date and time. The default mode is dateAndTime. See DatePickerMode for a list of mode constants. This is ignored if picker type is not .date.
    */
    public var datePickerMode: DatePickerMode = .dateAndTime {
        didSet {
            guard let picker = picker as? UIDatePicker else {
                return
            }
            switch datePickerMode {
            case .date: picker.datePickerMode = .date
            case .dateAndTime: picker.datePickerMode = .dateAndTime
            case .time: picker.datePickerMode = .time
            }
        }
    }

    /**
     The date of the date picker.

     Use this property to get and set the currently selected date. The default value of this property is the date when the UIDatePicker object is created. Setting this property animates the date picker by spinning the wheels to the new date and time; if you don't want any animation to occur when you set the date, use the setDate(_:animated:) method, passing false for the animated parameter. This is ignored if picker type is not .date.
    */
    public var date: Date {
        get {
            return _date
        }
        set {
            setDate(newValue, animated: true)
        }
    }
    private var _date = Date()

    /// The height of table view cell. Height is calculated dynamically based on whether or not the cell is expanded.
    public var estimatedHeightForRowSelected: CGFloat {
        let expandedHeight = unexpandedHeight + picker.bounds.height
        return isExpanded ? expandedHeight : unexpandedHeight
    }

    /// Returns an object initialized from data in a given unarchiver.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        pickerType = .default
        initialize()
    }

    /**
     Initializes and returns a newly allocated table cell object with the specified type of picker view embedded inside. This is the designated initializer for the class.
     - Parameter type: A constant indicating the picker style. See PickerType for descriptions of these constants.
     - Parameter reuseIdentifier: A string used to identify the cell object if it is to be reused for drawing multiple rows of a table view. Pass nil if the cell object is not to be reused. You should use the same reuse identifier for all cells of the same form.
    */
    public init(type: PickerType, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        pickerType = type
        initialize()
    }

    override convenience init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.init(type: .default, reuseIdentifier: reuseIdentifier)
    }

    private func initialize() {

        clipsToBounds = true

        if pickerType == .default {
            picker = UIPickerView()
            (picker as! UIPickerView).delegate = self
            (picker as! UIPickerView).dataSource = self
        } else {
            picker = UIDatePicker()
            (picker as! UIDatePicker).addTarget(self, action: #selector(UITableViewPickerCell.datePicked), for: .valueChanged)
            let timeIntervalSinceReferenceDateWithoutSeconds = floor(date.timeIntervalSinceReferenceDate / 60.0) * 60.0
            date = Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDateWithoutSeconds)
        }
        picker.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(separator)
        contentView.addSubview(picker)

        titleLabelHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: unexpandedHeight)
        titleLabelHeightConstraint?.isActive = true
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true

        valueLabelHeightConstraint = valueLabel.heightAnchor.constraint(equalToConstant: unexpandedHeight)
        valueLabelHeightConstraint?.isActive = true
        valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        valueLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true

        separatorHeightConstraint = separator.heightAnchor.constraint(equalToConstant: separatorHeight)
        separatorHeightConstraint?.isActive = true
        separator.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        separator.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        separator.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true

        picker.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        picker.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        picker.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
    }

    /**
     Expands or contracts the table cell depending on its current state. Call this method from the "tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)" delegate method to show or hide the picker view with an animation.
     - Parameter tableView: The UITableView object that contains the cell.
    */
    public func expand(_ tableView: UITableView, animated:Bool=true, completion:((Bool) -> Swift.Void)? = nil) {
        if !isExpanded {
            isExpanded = true
            updateForExpansion(tableView, animated: animated, completion: completion)
        }
    }

    public func contract(_ tableView: UITableView, animated:Bool=true, completion:((Bool) -> Swift.Void)? = nil) {
        if isExpanded {
            isExpanded = false
            updateForExpansion(tableView, animated: animated, completion: completion)
        }
    }

    public func updateForExpansion(_ tableView: UITableView, animated:Bool=true, completion:((Bool) -> Swift.Void)? = nil){
        func changeLabelColor(){
            self.valueLabel.textColor = self.isExpanded ? self.tintColor : self.defaultValueLabelTextColor
        }

        if animated{
            UIView.transition(with: valueLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
                changeLabelColor()
            }, completion:completion)
        }else{
            changeLabelColor()
            completion?(true)
        }

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    /**
     Sets the date to display in the date picker, with an option to animate the setting.
     - Parameter date: A Date object representing the new date to display in the date picker.
     - Parameter animated: true to animate the setting of the new date, otherwise false. The animation rotates the wheels until the new date and time is shown under the highlight rectangle.
    */
    public func setDate(_ date: Date, animated: Bool) {
        guard let picker = picker as? UIDatePicker else {
            return
        }
        _date = date
        picker.setDate(date, animated: animated)
        UITableViewPickerCell.dateFormatter.dateStyle = dateStyle
        UITableViewPickerCell.dateFormatter.timeStyle = timeStyle
        valueLabel.text = UITableViewPickerCell.dateFormatter.string(from: date)
    }

    /**
     Sets the row to display in the picker view, with an option to animate the setting.
     - Parameter row: A zero indexed number representing the new row to display in the picker view.
     - Parameter animated: true to animate the setting of the new row, otherwise false. The animation rotates the wheels until the new row is shown under the highlight rectangle.
     */
    public func setSelectedRow(_ row: Int, animated: Bool) {
        guard let picker = picker as? UIPickerView else {
            return
        }
        _selectedRow = row
        picker.selectRow(row, inComponent: 0, animated: animated)
        valueLabel.text = values[row]
    }

    @objc private func datePicked() {
        date = (picker as! UIDatePicker).date
        delegate?.pickerCell(self, didPick: selectedRow, value: date)
        didPickHandler?(self, selectedRow, date)
    }
}

extension UITableViewPickerCell: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return values[row]
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let value = values[row]
        valueLabel.text = value
        delegate?.pickerCell(self, didPick: row, value: value)
        didPickHandler?(self, selectedRow, value)
    }

}

extension UITableViewPickerCell: UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
}

private class ColorLockedView: UIView {
    var lockedBackgroundColor: UIColor {
        set {
            super.backgroundColor = newValue
        }
        get {
            return super.backgroundColor!
        }
    }
    override var backgroundColor: UIColor? {
        set {
        }
        get {
            return super.backgroundColor
        }
    }
}
