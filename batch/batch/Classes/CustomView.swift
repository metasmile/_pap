//
//  CustomView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 7. 12..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

@IBDesignable
class DesignableView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initialize()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        initialize()
    }
    
    open func initialize() {
        
    }
}

class RoundedView: DesignableView {
    @IBInspectable
    var cornerRadius: CGFloat = 6 {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func initialize() {
        super.initialize()
        
        clipsToBounds = true
    }
    
    override func layoutIfNeeded() {
        super.layoutSubviews()
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        layer.mask = maskLayer
    }
}

class CustomView: DesignableView {
    var containerView: UIView?
    var contentView: UIView?
    
    var nibName: String {
        return "\(type(of: self))"
    }
    
    open func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return nil }
        return view
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    override func initialize() {
        let containerView = self.containerView ?? self
        
        guard let view = loadViewFromNib() else { return }
        containerView.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        
        contentView = view
    }
}

@IBDesignable
class CustomCollectionViewCell: UICollectionViewCell {
    var containerView: UIView?
    
    var nibName: String {
        return "\(type(of: self))"
    }
    
    open func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return nil }
        return view
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    private func initialize() {
        guard let view = loadViewFromNib() else { return }
        contentView.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        
        containerView = view
        
        contentView.layoutIfNeeded()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        initialize()
        
        containerView?.prepareForInterfaceBuilder()
    }
}

@IBDesignable
class CustomCollectionReusableView: UICollectionReusableView {
    var containerView: UIView?
    
    var nibName: String {
        return "\(type(of: self))"
    }
    
    open func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return nil }
        return view
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    private func initialize() {
        guard let view = loadViewFromNib() else { return }
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        containerView = view
        
        layoutIfNeeded()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        initialize()
        
        containerView?.prepareForInterfaceBuilder()
    }
}
