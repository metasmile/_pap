//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
//TODO: integrate all.

/*
    Abstract Cells
*/
class UITableViewCellWithInclusiveHitTestSubview:UITableViewCell {
    private let TagForExcludingHitTest = Int(arc4random_uniform(2))

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let v = super.hitTest(point, with: event), v.tag==TagForExcludingHitTest {
            return v
        }
        return nil
    }

    fileprivate func setSubviewInclusiveHitTestTarget(_ subview:UIView){
        subview.tag = TagForExcludingHitTest
    }
}

class UITableViewIndicatorCell: UITableViewCell {
    override open func prepareForReuse() {
        super.prepareForReuse()

        stopIndicating()
    }

    func startIndicating(){
        if let view = self.accessoryView{
            self.startIndicating(targetSubview: view, position: .rightCenter)
        }
    }

    func stopIndicating(){
        if let view = self.accessoryView{
            self.stopIndicating(targetSubview: view)
        }
    }
}

/*
    UIControl Cells
*/
class UITableViewSwitchSubtitleCell: UITableViewSwitchCell /*UITableViewCellWithInclusiveHitTestSubview*/ {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UITableViewSwitchCell: UITableViewIndicatorCell /*UITableViewCellWithInclusiveHitTestSubview*/ {

    private(set) lazy var switcher: UISwitch = {
        let view = UISwitch()
        view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
//        self.setSubviewInclusiveHitTestTarget(view)
        return view
    }()

    var switchDidChange: ((Bool) -> Void)?

    override open func prepareForReuse() {
        super.prepareForReuse()

        switchDidChange = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryView = switcher
        detailTextLabel?.textColor = UIColor.gray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellSwitchDidChange(sender: UISwitch) {
        switchDidChange?(sender.isOn)
    }
}

class UITableViewSimpleValueCell: UITableViewCell {
    var valueLabelText: String?{
        didSet {
            valueLabel.text = valueLabelText
            valueLabel.textColor = tintColor
            valueLabel.sizeToFit()
            self.layoutIfNeeded()
        }
    }

    private var valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkText
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryView = valueLabel
        detailTextLabel?.textColor = UIColor.gray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        valueLabel.sizeToFit()
    }
}

class UITableViewActionSheetCell: UITableViewSimpleValueCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        let g = UITapGestureRecognizer(target: self, action: #selector(tapped))
        g.cancelsTouchesInView = true
        self.addGestureRecognizer(g)

        detailTextLabel?.textColor = UIColor.gray
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

        let alert = UIAlertController.actionSheet(title: actionSheetTitleText, message: actionSheetMessageText)

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

        UIViewController.present(alert, animated: true) {
            self.actionSheetPresented?(alert)
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        valueLabelText = valueLabelText
    }
}


class UITableViewStepperCell: UITableViewCellWithInclusiveHitTestSubview {
    private(set) lazy var stepper: UIStepper = UIStepper()

    var didChangeValue: ((Double) -> Void)?

    override open func prepareForReuse() {
        super.prepareForReuse()

        didChangeValue = nil
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        stepper.addTarget(self, action: #selector(self.valueDidChange), for: .valueChanged)

        accessoryView = stepper

        detailTextLabel?.textColor = UIColor.gray

        self.setSubviewInclusiveHitTestTarget(stepper)

        self.detailTextLabel?.textColor = UIColor.gray
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func valueDidChange(sender: UIStepper) {
        UIFeedback.select()
        didChangeValue?(sender.value)
    }
}

class UITableViewButtonCell: UITableViewIndicatorCell {
    private(set) lazy var button: UIButton = UIButton()

    var touchAreaOnlyButton:Bool = false
    var didTap: (() -> ())?
    var buttonFrameInset:UIEdgeInsets?

    override open func prepareForReuse() {
        super.prepareForReuse()
        
        button.setTitle(nil, for: .normal)
        button.setAttributedTitle(nil, for: .normal)

        didTap = nil
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        button.addTarget(self, action: #selector(self.buttonDidTap), for: .touchUpInside)

        accessoryView = button

        detailTextLabel?.textColor = UIColor.gray
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == button ? self : hitView
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        setHighlighted(true, animated: false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        setHighlighted(false, animated: true)

        if !touchAreaOnlyButton{
            for touch in touches{
                if let _ = touch.view{
                    UIFeedback.select()
                    didTap?()
                    break
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        setHighlighted(false, animated: false)
    }

    func setButtonTitle(title: String, detailTitle: String?=nil, for state: UIControl.State) {
        guard let _detailTitle = detailTitle else {
            button.setTitle(title, for: .normal)
            return
        }

        let wholeText = "\(title)\n\(_detailTitle)"

        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .right

        let titleFont = button.titleLabel?.font ?? UIFont.systemFont(ofSize: UIFont.buttonFontSize)
        let titleFontColor:UIColor = button.titleColor(for: state) ?? self.tintColor

        let detailTitleFont = detailTextLabel?.font ?? UIFont.systemFont(ofSize: titleFont.pointSize/0.5)
        let detailTitleFontColor = detailTextLabel?.textColor ?? UIColor.gray

        let attributedString = NSMutableAttributedString(string: wholeText, attributes: nil)

        let titleRange = (attributedString.string as NSString).range(of: title)
        let detailTitleRange = (attributedString.string as NSString).range(of: _detailTitle)

        attributedString.setAttributes([NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: titleFontColor], range: titleRange)
        attributedString.setAttributes([NSAttributedString.Key.font: detailTitleFont, NSAttributedString.Key.foregroundColor: detailTitleFontColor], range: detailTitleRange)

        button.setAttributedTitle(attributedString, for: state)
    }

    override open func layoutSubviews() {
        button.sizeToFit()
        if let inset = self.buttonFrameInset {
            button.frame = button.frame.inset(by: inset)
        }

        super.layoutSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func buttonDidTap(sender: UIButton) {
        didTap?()
    }
}

class UITableViewSegmentedControlCell: UITableViewCellWithInclusiveHitTestSubview {
    private(set) lazy var segmentedControl: UISegmentedControl = UISegmentedControl(items: [])

    var didChangeValue: ((Int) -> Void)?

    override open func prepareForReuse() {
        super.prepareForReuse()

        didChangeValue = nil
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryView = segmentedControl

        detailTextLabel?.textColor = UIColor.gray

        self.setSubviewInclusiveHitTestTarget(segmentedControl)

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
        UIFeedback.select()
        didChangeValue?(sender.selectedSegmentIndex)
    }
}

public class UITableViewCustomViewAccessoryCellDescriber: UITableViewCellDescriber {
    public override var cellClass:Swift.AnyClass { return UITableViewCustomViewAccessoryCell.self }

    public var accessoryGenerator: (() -> UIView?)?
}

class UITableViewCustomViewAccessoryCell: UITableViewCell {
    var enableMultilineTitleLabel:Bool = true //TODO: move to some common class

    var customAccessoryView: UIView? {
        didSet {
            customAccessoryView?.removeFromSuperview()

            if let view = customAccessoryView {
                contentView.addSubview(view)
            }

            layoutIfNeeded()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        textLabel?.allowsDefaultTighteningForTruncation = true
        
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()

        let textContentWidth = contentView.bounds.width - (customAccessoryView?.bounds.width ?? 0) - 12
        textLabel?.frame.size.width = textContentWidth
        detailTextLabel?.frame.size.width = textContentWidth

        if enableMultilineTitleLabel{
            textLabel?.numberOfLines = 0;
            textLabel?.lineBreakMode = .byWordWrapping
            textLabel?.sizeToFit()
            textLabel?.centerToParent(options: [.vertical])
        }else{
            textLabel?.numberOfLines = 1
            textLabel?.sizeToFit()
            textLabel?.adjustsFontSizeToFitWidth = true
        }

        detailTextLabel?.adjustsFontSizeToFitWidth = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutIfNeeded()
    }
}
