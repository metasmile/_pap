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
