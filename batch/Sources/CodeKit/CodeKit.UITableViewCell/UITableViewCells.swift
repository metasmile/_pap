//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
//TODO: integrate all.

open class UITableViewSwitchCell: UITableViewCell {
    private(set) lazy var switcher: UISwitch = {
        let view = UISwitch()
        view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
        return view
    }()

    var switchDidChange: ((Bool) -> Void)?

    override open func prepareForReuse() {
        super.prepareForReuse()

        switchDidChange = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryView = switcher
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }
}

open class UITableViewSimpleValueCell: UITableViewCell {
    var valueLabelText: String?{
        didSet {
            valueLabel.text = valueLabelText
            valueLabel.sizeToFit()
            self.layoutIfNeeded()
        }
    }

    private var valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkText
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryView = valueLabel
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        valueLabel.sizeToFit()
    }
}

open class UITableViewActionSheetCell: UITableViewSimpleValueCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        let g = UITapGestureRecognizer(target: self, action: #selector(tapped))
        g.cancelsTouchesInView = true
        self.addGestureRecognizer(g)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var actionSheetTitleText:String?
    public var actionSheetMessageText:String?
    public var valueLabels:[String]?

    public var valueSelected:((UIAlertAction, Int?) -> ())?
    public var cancelled:((UIAlertAction) -> ())?
    public var actionSheetPresented:((UIAlertController) -> ())?

    @objc func tapped(r: UITapGestureRecognizer) {

        let alert = UIAlertController(title: actionSheetTitleText, message: actionSheetMessageText, preferredStyle: .actionSheet)

        if let labels = valueLabels {
            for l in labels {
                alert.addAction(UIAlertAction(title: l, style: . default, handler: { action in
                    if let title = action.title{
                        self.valueSelected?(action, self.valueLabels?.index(of: title))
                        self.valueLabelText = title
                    }
                }))
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: cancelled))

        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true) {
            self.actionSheetPresented?(alert)
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        valueLabelText = valueLabelText
    }
}


open class UITableViewStepperCell: UITableViewCell {
    private(set) lazy var stepper: UIStepper = UIStepper()

    var didChangeValue: ((Double) -> Void)?

    override open func prepareForReuse() {
        super.prepareForReuse()

        didChangeValue = nil
    }

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        stepper.addTarget(self, action: #selector(self.valueDidChange), for: .valueChanged)

        accessoryView = stepper

        self.detailTextLabel?.textColor = UIColor.gray
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func valueDidChange(sender: UIStepper) {
        didChangeValue?(sender.value)
    }
}


open class UITableViewSegmentedControlCell: UITableViewCell {
    private(set) lazy var segmentedControl: UISegmentedControl = UISegmentedControl(items: [])

    var didChangeValue: ((Int) -> Void)?

    override open func prepareForReuse() {
        super.prepareForReuse()

        didChangeValue = nil
    }

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryView = segmentedControl

        segmentedControl.addTarget(self, action: #selector(self.valueDidChange), for: .valueChanged)

        self.detailTextLabel?.textColor = UIColor.gray
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func valueDidChange(sender: UISegmentedControl) {
        print(sender.selectedSegmentIndex)
        didChangeValue?(sender.selectedSegmentIndex)
    }
}

public struct UIPickerItem {
    var component: String
    var values = [String]()
}

open class UITableViewMultiplePickerCell: UITableViewCell, UITableViewExpandableCell, UIPickerViewDataSource, UIPickerViewDelegate {
    private(set) lazy var picker: UIPickerView = {
        let view = UIPickerView()
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
    private var titleLabelHeightConstraint: NSLayoutConstraint?
    private var valueLabelHeightConstraint: NSLayoutConstraint?
    private var separatorHeightConstraint: NSLayoutConstraint?
    
    public var unexpandedHeight: CGFloat = 44.0 {
        didSet {
            titleLabelHeightConstraint?.constant = unexpandedHeight
            valueLabelHeightConstraint?.constant = unexpandedHeight
        }
    }
    
    public var separatorHeight: CGFloat = 0.5 {
        didSet {
            separatorHeightConstraint?.constant = separatorHeight
        }
    }
    
    private(set) public var isExpanded = false
    
    var pickerDidChange: ((_ cell: UITableViewMultiplePickerCell, _ row: Int, _ component: Int, _ value: Any) -> ())?
    
    public var values = [UIPickerItem]()
    
    private var _selectedRow = [Int: Int]()
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        
        pickerDidChange = nil
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        clipsToBounds = true
        
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
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var estimatedHeightForRowSelected: CGFloat {
        let expandedHeight = unexpandedHeight + picker.bounds.height
        return isExpanded ? expandedHeight : unexpandedHeight
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return values.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values[component].values.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        _selectedRow[component] = row
        pickerDidChange?(self, row, component, values[component].values[row])
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.text = values[component].values[row]
        label.sizeToFit()
        return label
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
    
    public func setSelectedRow(_ row: Int, inComponent component: Int, animated: Bool) {
        picker.selectRow(row, inComponent: component, animated: animated)
        _selectedRow[component] = row
    }
    
    public func selectedRow(for component: Int) -> Int {
        return max(0, min(values[component].values.count - 1, (_selectedRow[component] ?? 0)))
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
}
