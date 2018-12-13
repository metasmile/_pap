//
// Created by BLACKGENE on 2018-12-13.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit


// PrecisionLevelSlider.swift
//
// Copyright (c) 2016 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

open class PrecisionLevelSlider: UIControl {

    // MARK: - Properties
    open var longNotchColor: UIColor = .black {
        didSet {
            update()
        }
    }

    open var shortNotchColor: UIColor = UIColor(white: 0.2, alpha: 1) {
        didSet {
            update()
        }
    }

    open var centerNotchColor: UIColor = UIColor.orange {
        didSet {
            update()
        }
    }

    open var numberOfNotches: Int = 30 {
        didSet {
            update()
        }
    }

    /// default 0.0. this value will be pinned to min/max
    @objc dynamic open var value: Float = 0 {
        didSet {

            guard !scrollView.isDecelerating && !scrollView.isDragging else {
                return
            }

            setValue(value, animated: true)
        }
    }

    open func setValue(_ value: Float, animated: Bool) {
        let offset = valueToOffset(value: value)

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {

                self.scrollView.setContentOffset(offset, animated: false)

            }) { (finish) in
            }
        }
        else {
            self.scrollView.setContentOffset(offset, animated: false)
        }
    }

    /// default 0.0. the current value may change if outside new min value
    @objc dynamic open var minimumValue: Float = 0 {
        didSet {

        }
    }

    /// default 1.0. the current value may change if outside new max value
    @objc dynamic open var maximumValue: Float = 1 {
        didSet {

        }
    }

    @objc dynamic open var defaultValue: Float = 0 {
        didSet {
            defaultValueMark.position.x = valueToOffset(value: defaultValue).x + scrollView.contentInset.left
            defaultValueMark.position.y = 8
        }
    }

    open var isContinuous: Bool = true

    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()

    private lazy var defaultValueMark: CAShapeLayer = {
        let layer = CAShapeLayer()

        let markSize: CGFloat = 6
        layer.path = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: -markSize / 2, y: -markSize / 2), size: CGSize(width: markSize, height: markSize))).cgPath
        layer.actions = ["position": NSNull()]

        return layer
    }()
    private lazy var centerNotchLayer = CALayer()

    private lazy var gradientLayer: CAGradientLayer = {

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradientLayer.locations = [0, 0.4, 0.6, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)

        return gradientLayer
    }()


    // MARK: - Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Functions
    open override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }

    func update() {

        let offset = valueToOffset(value: value)
        scrollView.setContentOffset(offset, animated: false)

        gradientLayer.frame = bounds
        let notchWidth: CGFloat = 1

        let interval = floor((bounds.size.width) / CGFloat(numberOfNotches))

        let longNotchHeight: CGFloat = 10
        let shortNotchHeight: CGFloat = 8
        let offsetY = bounds.height / 2

        let notchLayers: [CALayer] = {
            return (0...numberOfNotches).map { _ -> CALayer in
                CALayer()
            }
        }()

        notchLayers.enumerated().forEach { i, l in

            let x: CGFloat = CGFloat(i) * interval

            if i % 5 == 0 {
                l.backgroundColor = longNotchColor.cgColor

                l.frame = CGRect(
                        x: x,
                        y: offsetY - (longNotchHeight / 2),
                        width: notchWidth,
                        height: longNotchHeight)

            } else {
                l.backgroundColor = shortNotchColor.cgColor
                l.frame = CGRect(
                        x: x,
                        y: offsetY - (shortNotchHeight / 2),
                        width: notchWidth,
                        height: shortNotchHeight)
            }
        }

        contentView.layer.sublayers = notchLayers
        contentView.layer.addSublayer(defaultValueMark)

        defaultValueMark.fillColor = shortNotchColor.cgColor

        centerNotchLayer.backgroundColor = centerNotchColor.cgColor
        centerNotchLayer.frame = CGRect(x: bounds.midX, y: 0, width: notchWidth, height: bounds.height)

        let contentSize = CGSize(
                width: notchLayers.last!.frame.maxX - notchWidth,
                height: bounds.height
        )

        contentView.frame.size = contentSize
        scrollView.contentSize = contentSize

        let inset = contentSize.width / 2 + (max(0, scrollView.bounds.width - contentSize.width) / 2)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)

    }

    func setup() {

        layer.mask = gradientLayer

        backgroundColor = UIColor.clear

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self

        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        layer.addSublayer(centerNotchLayer)
    }

    fileprivate func offsetToValue() -> Float {
        return value(with: scrollView.contentOffset)
    }

    fileprivate func value(with offset: CGPoint) -> Float {
        let progress = (offset.x + scrollView.contentInset.left) / contentView.bounds.size.width
        let actualProgress = Float(min(max(0, progress), 1))
        let value = ((maximumValue - minimumValue) * actualProgress) + minimumValue

        return value
    }

    fileprivate func valueToOffset(value: Float) -> CGPoint {

        let progress = (value - minimumValue) / (maximumValue - minimumValue)
        let x = contentView.bounds.size.width * CGFloat(progress) - scrollView.contentInset.left
        return CGPoint(x: x, y: 0)
    }

    private var needsStickToDefaultValue: Bool = false {
        didSet {
            if needsStickToDefaultValue {
                if oldValue == false {
                    UIFeedback.select()

                    stickTouchLocation = scrollView.panGestureRecognizer.location(in: self)

                    defaultValueMark.isHidden = true
                }
                else {
                    defaultValueMark.isHidden = false
                }

                value = defaultValue
                setValue(defaultValue, animated: false)
                sendActions(for: .valueChanged)
            }
            else {
                defaultValueMark.isHidden = false
            }
        }
    }
    private var stickTouchLocation: CGPoint = .zero
    private var beginningScrollPosition: CGPoint = .zero
    private var previousScrollPosition: CGPoint = .zero

    var exponentialValue: Float {
//        let easeInExpo = CubicBezier(controlPoints: 0.95, 0.05, 0.795, 0.035)

        let size = CGSize(width: scrollView.contentSize.width / 2, height: bounds.size.height)
        let easeInExpo = CubicBezier(from: .zero, controlPoint1: CGPoint(x: size.width * 0.95, y: size.height * 0.05), controlPoint2: CGPoint(x: size.width * 0.795, y: size.height * 0.35), to: CGPoint(x: size.width, y: size.height))

        let t = (value - minimumValue) / (maximumValue - minimumValue)

        print(#function, t, easeInExpo.point(at: CGFloat(t)))

        return value(with: CGPoint(x: easeInExpo.y(at: CGFloat(t)), y: 0))

//        let actualProgress = Float(min(max(0, easeInExpo.y(at: CGFloat(t))), 1))
//        return ((maximumValue - minimumValue) * actualProgress) + minimumValue
    }
}

fileprivate struct CubicBezier {
    // http://www.paulwrightapps.com/blog/2014/9/4/finding-the-position-and-angle-of-points-along-a-bezier-curve-on-ios

    // cubic bezier control points
    private(set) var c0 = CGPoint.zero
    private(set) var c1 = CGPoint.zero
    private(set) var c2 = CGPoint.zero
    private(set) var c3 = CGPoint.zero

    // cubic bezier polynomial coefficients
    var p0: CGPoint {
        let x = c3.x - 3 * c2.x + 3 * c1.x - c0.x
        let y = c3.y - 3 * c2.y + 3 * c1.y - c0.y
        return CGPoint(x: x, y: y)
    }
    var p1: CGPoint {
        let x = 3 * c2.x - 6 * c1.x + 3 * c0.x
        let y = 3 * c2.y - 6 * c1.y + 3 * c0.y
        return CGPoint(x: x, y: y)
    }
    var p2: CGPoint {
        let x = 3 * c2.x - 6 * c1.x + 3 * c0.x
        let y = 3 * c2.y - 6 * c1.y + 3 * c0.y
        return CGPoint(x: x, y: y)
    }
    var p3: CGPoint {
        return c0
    }

    init(from c0: CGPoint, controlPoint1 c1: CGPoint, controlPoint2 c2: CGPoint, to c3: CGPoint) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
    }

    init(controlPoints c1: CGPoint, _ c2: CGPoint) {
        self.init(from: .zero, controlPoint1: c1, controlPoint2: c2, to: CGPoint(x: 1, y: 1))
    }

    init(controlPoints c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat) {
        self.init(controlPoints: CGPoint(x: c1x, y: c1y), CGPoint(x: c2x, y: c2y))
    }

    func x(at t: CGFloat) -> CGFloat {
        return ((p0.x * t + p1.x) * t + p2.x) * t + p3.x
    }

    func y(at t: CGFloat) -> CGFloat {
        return ((p0.y * t + p1.y) * t + p2.y) * t + p3.y
    }

    func point(at t: CGFloat) -> CGPoint {
        return CGPoint(x: x(at: t), y: y(at: t))
    }

    func angle(at t: CGFloat) -> CGFloat {
        let dxdt = 3 * p0.x * t * t + 2 * p1.x * t + p2.x
        let dydt = 3 * p0.y * t * t + 2 * p1.y * t + p2.y
        return atan2(dydt, dxdt)
    }
}

extension PrecisionLevelSlider {
    enum Direction {
        case none
        case left
        case right
    }

    private var stickTouchDifference: CGFloat {
        return scrollView.panGestureRecognizer.location(in: self).x - stickTouchLocation.x
    }

    private var scrollOffsetDifference: CGFloat {
        return scrollView.contentOffset.x - beginningScrollPosition.x
    }

    private var scrollDirection: Direction {
        return scrollOffsetDifference == 0 ? .none : (scrollOffsetDifference < 0 ? .left : .right)
    }

    private var sliderDifference: CGFloat {
        return scrollView.contentOffset.x - previousScrollPosition.x
    }

    private var sliderDirection: Direction {
        return sliderDifference == 0 ? .none : (sliderDifference < 0 ? .left : .right)
    }

    private var defaultValueOffsetDifference: CGFloat {
        return scrollView.contentOffset.x - valueToOffset(value: defaultValue).x
    }

    private var directionFromDefault: Direction {
        return defaultValueOffsetDifference == 0 ? .none : (defaultValueOffsetDifference < 0 ? .left : .right)
    }
}

extension PrecisionLevelSlider: UIScrollViewDelegate {
    public final func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginningScrollPosition = scrollView.contentOffset
        previousScrollPosition = scrollView.contentOffset
    }

    public final func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else {
            return
        }

        guard scrollView.isDecelerating || scrollView.isDragging else {
            return
        }

        if isContinuous {
            if needsStickToDefaultValue, stickTouchDifference.magnitude < 8 {
                scrollView.contentOffset = valueToOffset(value: defaultValue)
                value = defaultValue
            }
            else {
                value = offsetToValue()

                needsStickToDefaultValue = (scrollView.isTracking && sliderDirection != directionFromDefault && defaultValueOffsetDifference.magnitude < 8)
            }

            sendActions(for: .valueChanged)

            previousScrollPosition = scrollView.contentOffset
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isContinuous == false {
            value = offsetToValue()
            sendActions(for: .valueChanged)
        }
        defaultValueMark.isHidden = false
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
}
