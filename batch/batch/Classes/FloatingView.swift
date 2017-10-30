//
//  FloatingView.swift
//  batch
//
//  Created by Hyojin Mo on 2017. 10. 25..
//  Copyright © 2017년 Codeful. All rights reserved.
//
// http://blog.maxrudberg.com/post/165590234593/ui-design-for-iphone-x-bottom-elements
//

import UIKit

class FloatingView: DesignableView {
    var roundedContainerView: RoundedView!
    var shadowLayer: CAShapeLayer!
    var borderLayer: CAShapeLayer!
    
    var borderColor = UIColor.white {
        didSet {
            borderLayer.strokeColor = borderColor.cgColor
        }
    }
    
    override func initialize() {
        super.initialize()
        
        shadowLayer = CAShapeLayer()
        shadowLayer.shadowOffset = .zero
        shadowLayer.shadowOpacity = 0.1
        shadowLayer.shadowRadius = 3
        shadowLayer.shadowColor = UIColor.black.cgColor
        layer.addSublayer(shadowLayer)
        
        let cornerRadius: CGFloat = 8
        
        roundedContainerView = RoundedView(frame: bounds)
        roundedContainerView.cornerRadius = cornerRadius
        addSubview(roundedContainerView)
        
        roundedContainerView.translatesAutoresizingMaskIntoConstraints = false
        roundedContainerView.topAnchor.constraint(equalTo: topAnchor, constant: cornerRadius).isActive = true
        roundedContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -cornerRadius).isActive = true
        roundedContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: cornerRadius).isActive = true
        roundedContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -cornerRadius).isActive = true
        
        borderLayer = CAShapeLayer()
        borderLayer.lineWidth = 1
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.opacity = 0.7
        layer.addSublayer(borderLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.path = UIBezierPath(roundedRect: roundedContainerView.frame, cornerRadius: roundedContainerView.cornerRadius).cgPath
        shadowLayer.shadowPath = UIBezierPath(roundedRect: roundedContainerView.frame, cornerRadius: roundedContainerView.cornerRadius * 0.5).cgPath
    }
}

class FloatingContentView: CustomView {
    var floatingView: FloatingView!
    
    @IBInspectable var borderColor = UIColor.white {
        didSet {
            floatingView.borderColor = borderColor
        }
    }
    
    override func initialize() {
        floatingView = FloatingView(frame: bounds)
        addSubview(floatingView)
        
        floatingView.translatesAutoresizingMaskIntoConstraints = false
        floatingView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        floatingView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        floatingView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        floatingView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        containerView = floatingView.roundedContainerView
        
        super.initialize()
    }
}

extension UIView {
    static func animateUsingSpring(duration: TimeInterval, delay: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: animations, completion: completion)
    }
    
    func animateUsingSpringIfLayoutConstraintsChanged() {
        UIView.animateUsingSpring(duration: 0.3, delay: 0.0, animations: { [unowned self] in
            self.superview?.layoutIfNeeded()
            }, completion: nil)
    }
}
