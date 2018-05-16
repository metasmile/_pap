//
//  CustomView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 7. 12..
//  Copyright © 2017년 Codeful. All rights reserved.
//

import UIKit

extension UIView {
    func fitConstraints(to view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}

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
            layer.masksToBounds = true
            layer.cornerRadius = cornerRadius
        }
    }
    
    override func initialize() {
        super.initialize()
    }
}

class CustomView: DesignableView {
    weak var containerView: UIView?
    weak var contentView: UIView?
    
    var nibName: String {
        return "\(type(of: self))"
    }
    
    open func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return nil }
        return view
    }
    
    override func initialize() {
        let containerView = self.containerView ?? self
        
        guard let view = loadViewFromNib() else { return }
        containerView.addSubview(view)
        
        view.fitConstraints(to: containerView)
        
        contentView = view
    }
}

@IBDesignable
class CustomCollectionViewCell: UICollectionViewCell {
    weak var containerView: UIView?
    
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
    
    func initialize() {
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
    weak var containerView: UIView?
    
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
