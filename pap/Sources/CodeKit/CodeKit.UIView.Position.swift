//
//  UIView+Positioning.swift
//
//  Created by Shai Mishali on 1/19/15.
//  Copyright (c) 2015 Shai Mishali. All rights reserved.
//  https://github.com/freak4pc/UIView-Positioning/blob/master/UIView%2BPositioning.swift
//

import Foundation
import UIKit

//INFO: x(horizontal) -> y(vertical) arrangement (e.g. left(x)Top(y))
enum UIViewFrameAlignment {
    case leftTop
    case rightTop
    case rightBottom
    case leftBottom
    case center
    case rightCenter
    case leftCenter
    case centerTop
    case centerBottom

    func alignFrame(view:UIView, for containerView:UIView){
        switch (self){
            case .leftTop:
                view.left = containerView.left
                view.top = containerView.top
            case .rightTop:
                view.right = containerView.right
                view.top = containerView.top
            case .rightBottom:
                view.right = containerView.right
                view.bottom = containerView.bottom
            case .leftBottom:
                view.left = containerView.left
                view.bottom = containerView.bottom
            case .center:
                view.center = containerView.center
            case .rightCenter:
                view.right = containerView.right
                view.centerY = containerView.centerY
            case .leftCenter:
                view.left = containerView.left
                view.centerY = containerView.centerY
            case .centerTop:
                view.centerX = containerView.centerX
                view.top = containerView.top
            case .centerBottom:
                view.centerX = containerView.centerX
                view.bottom = containerView.bottom
        }
    }
}

struct UIViewCenterToParentOption: OptionSet {
    public let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }

    static let vertical = UIViewCenterToParentOption(1 << 0)
    static let horizontal = UIViewCenterToParentOption(1 << 1)
}


extension UIView {
    // MARK: - Basic Properties

    @objc
    var visible:Bool {
        set { self.isHidden = !newValue }
        get { return !self.isHidden }
    }

    /// X Axis value of UIView.
    @objc
    var x: CGFloat {
        set { self.frame = CGRect(x: _pixelIntegral(newValue),
                y: self.y,
                width: self.width,
                height: self.height)
        }
        get { return self.frame.origin.x }
    }

    /// Y Axis value of UIView.
    @objc
    var y: CGFloat {
        set { self.frame = CGRect(x: self.x,
                y: _pixelIntegral(newValue),
                width: self.width,
                height: self.height)
        }
        get { return self.frame.origin.y }
    }

    /// Width of view.
    @objc
    var width: CGFloat {
        set { self.frame = CGRect(x: self.x,
                y: self.y,
                width: _pixelIntegral(newValue),
                height: self.height)
        }
        get { return self.frame.size.width }
    }

    /// Height of view.
    @objc
    var height: CGFloat {
        set { self.frame = CGRect(x: self.x,
                y: self.y,
                width: self.width,
                height: _pixelIntegral(newValue))
        }
        get { return self.frame.size.height }
    }

    // MARK: - Origin and Size

    /// View's Origin point.
    @objc
    var origin: CGPoint {
        set { self.frame = CGRect(x: _pixelIntegral(newValue.x),
                y: _pixelIntegral(newValue.y),
                width: self.width,
                height: self.height)
        }
        get { return self.frame.origin }
    }

    /// View's size.
    @objc
    var size: CGSize {
        set { self.frame = CGRect(x: self.x,
                y: self.y,
                width: _pixelIntegral(newValue.width),
                height: _pixelIntegral(newValue.height))
        }
        get { return self.frame.size }
    }

    // MARK: - Extra Properties

    /// View's right side (x + width).
    @objc
    var right: CGFloat {
        set { self.x = newValue - self.width }
        get { return self.x + self.width }
    }

    /// View's bottom (y + height).
    @objc
    var bottom: CGFloat {
        set { self.y = newValue - self.height }
        get { return self.y + self.height }
    }

    /// View's top (y).
    @objc
    var top: CGFloat {
        set { self.y = newValue }
        get { return self.y }
    }

    /// View's left side (x).
    @objc
    var left: CGFloat {
        set { self.x = newValue }
        get { return self.x }
    }

    /// View's center X value (center.x).
    @objc
    var centerX: CGFloat {
        set { self.center = CGPoint(x: newValue, y: self.centerY) }
        get { return self.center.x }
    }

    /// View's center Y value (center.y).
    @objc
    var centerY: CGFloat {
        set { self.center = CGPoint(x: self.centerX, y: newValue) }
        get { return self.center.y }
    }

    /// Last subview on X Axis.
    @objc
    var lastSubviewOnX: UIView? {
        return self.subviews.reduce(UIView(frame: .zero)) {
            return $1.x > $0.x ? $1 : $0
        }
    }

    /// Last subview on Y Axis.
    @objc
    var lastSubviewOnY: UIView? {
        return self.subviews.reduce(UIView(frame: .zero)) {
            return $1.y > $0.y ? $1 : $0
        }
    }

    // MARK: - Bounds Methods

    /// X value of bounds (bounds.origin.x).
    @objc
    var boundsX: CGFloat {
        set { self.bounds = CGRect(x: _pixelIntegral(newValue),
                y: self.boundsY,
                width: self.boundsWidth,
                height: self.boundsHeight)
        }
        get { return self.bounds.origin.x }
    }

    /// Y value of bounds (bounds.origin.y).
    @objc
    var boundsY: CGFloat {
        set { self.frame = CGRect(x: self.boundsX,
                y: _pixelIntegral(newValue),
                width: self.boundsWidth,
                height: self.boundsHeight)
        }
        get { return self.bounds.origin.y }
    }

    /// Width of bounds (bounds.size.width).
    @objc
    var boundsWidth: CGFloat {
        set { self.frame = CGRect(x: self.boundsX,
                y: self.boundsY,
                width: _pixelIntegral(newValue),
                height: self.boundsHeight)
        }
        get { return self.bounds.size.width }
    }

    /// Height of bounds (bounds.size.height).
    @objc
    var boundsHeight: CGFloat {
        set { self.frame = CGRect(x: self.boundsX,
                y: self.boundsY,
                width: self.boundsWidth,
                height: _pixelIntegral(newValue))
        }
        get { return self.bounds.size.height }
    }

    // MARK: - Useful Methods

    /// Center view to it's parent view.
    func centerToParent(options:UIViewCenterToParentOption = [.vertical, .horizontal]) {
        guard let superview = self.superview else { return }

        if UIApplication.shared.keyWindowInScenes?.windowScene?.interfaceOrientation.isLandscape ?? false {
            self.origin = CGPoint(x: options.contains(.vertical) ? (superview.height / 2) - (self.height / 2) : origin.x, y: options.contains(.horizontal) ? (superview.width / 2) - (self.width / 2) : origin.y)
        }else{
            self.origin = CGPoint(x: options.contains(.horizontal) ? (superview.width / 2) - (self.width / 2) : origin.x, y: options.contains(.vertical) ? (superview.height / 2) - (self.height / 2) : origin.y)
        }
    }

    // MARK: - Private Methods
    fileprivate func _pixelIntegral(_ pointValue: CGFloat) -> CGFloat {
        let scale = UIScreen.main.scale
        return (round(pointValue * scale) / scale)
    }
}


