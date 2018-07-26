//
// Created by BLACKGENE on 26.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

protocol ChargeableButtonAppearance {
    var emptyImage:UIImage?{get}
    var filledImage:UIImage?{get}
}

class ChargeableButton: UIButton {
    struct ChargeType: OptionSet {
        public let rawValue: Int

        init(rawValue: Int) {
            self.rawValue = rawValue
        }

        init(_ rawValue: Int) {
            self.rawValue = rawValue
        }

        static let fill = ChargeType(1 << 0)
        static let opacity = ChargeType(1 << 1)
    }

    private var appearanceDelegate: ChargeableButtonAppearance?

    convenience init(type buttonType: UIButtonType, appearance: ChargeableButtonAppearance){
        self.init(type: buttonType)
        appearanceDelegate = appearance
    }

    private enum ChargeLevel: CGFloat {
        case warning = 0.1
        case low = 0.2
        case high = 0.8
        case full = 1

        static func `init`(balance: CGFloat) -> ChargeLevel {
            if balance < ChargeLevel.warning.rawValue {
                return ChargeLevel.warning
            }
            else if balance < ChargeLevel.low.rawValue {
                return ChargeLevel.low
            }
//            else if ratio == ChargeLevel.full.rawValue {
//                return ChargeLevel.full
//            }
            else {
                return ChargeLevel.high
            }
        }

        var representativeColor: UIColor? {
            switch self {
            case .warning: return UIColor(red: 0.92, green: 0.3, blue: 0.25, alpha: 1)
            case .low: return UIColor(red: 0.97, green: 0.8, blue: 0.27, alpha: 1)
            case .full: return UIColor(red: 0.46, green: 0.97, blue: 0.36, alpha: 1)
            default: return nil
            }
        }

        var animation: CAAnimation? {
            switch self {
            case .warning:
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 1
                animation.toValue = 0.5
                animation.duration = 0.75
                animation.repeatCount = Float.infinity
                animation.autoreverses = true
                return animation
            case .low:
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 1
                animation.toValue = 0.5
                animation.duration = 1.5
                animation.repeatCount = Float.infinity
                animation.autoreverses = true
                return animation
            default: return nil
            }
        }
    }

    var chargeType: ChargeType = [.fill, .opacity]
    var showsColorLevel = true
    var showsAnimation = true
    private var levelAnimations = [ChargeLevel: CAAnimation]()

    var balance: Double? {
        didSet {
            let ratio: CGFloat = CGFloat(balance ?? 0)
            let level: ChargeLevel = ChargeLevel(balance: ratio)
            let color: UIColor = showsColorLevel ? level.representativeColor ?? tintColor : tintColor

            guard let iconImage = appearanceDelegate?.filledImage?.tintColor(color) else { return }

            let imageBounds = CGRect(origin: .zero, size: iconImage.size)
            let buttonImage = UIGraphicsImageRenderer(bounds: imageBounds).imageWithCurrentContext { (ctx) in
                if self.chargeType.contains(.opacity) {
                    iconImage.draw(at: .zero, blendMode: .normal, alpha: ratio == 1 ? 1 : ratio / 2 + 0.1)
                }

                if self.chargeType.contains(.fill) {
                    ctx.saveGState()

                    ctx.addRect(CGRect(x: 0, y: imageBounds.height - imageBounds.height * ratio, width: imageBounds.width, height: imageBounds.height * ratio))
                    ctx.clip(using: .evenOdd)

                    iconImage.draw(at: .zero, blendMode: .multiply, alpha: 0.3)

                    ctx.restoreGState()
                }

                appearanceDelegate?.emptyImage?.tintColor(UIColor.black).draw(at: .zero)
                ctx.setBlendMode(.multiply)
                appearanceDelegate?.emptyImage?.tintColor(color).draw(at: .zero)

            }?.withRenderingMode(.alwaysOriginal)

            setImage(buttonImage, for: .normal)

            if showsAnimation {
                let animationKey = "chargeAnimation"
                if let _ = levelAnimations[level] {}
                else if let anim = level.animation {
                    levelAnimations.removeAll()
                    levelAnimations[level] = anim

                    imageView?.layer.removeAllAnimations()
                    imageView?.layer.add(anim, forKey: animationKey)
                }
                else {
                    imageView?.layer.removeAllAnimations()
                    levelAnimations.removeAll()
                }
            }
            else {
                imageView?.layer.removeAllAnimations()
                levelAnimations.removeAll()
            }
        }
    }
}

class ChargeableBarButtonItem: UIBarButtonItem {

    private lazy var chargeableButton:ChargeableButton? = customView as? ChargeableButton

    public convenience init(button: ChargeableButton){
        self.init()
        customView = button
    }

    override var title: String? {
        set {
            chargeableButton?.setTitle(newValue, for: .normal)
            chargeableButton?.sizeToFit()
        }

        get {
            return chargeableButton?.title(for: .normal)
        }
    }

    var balance: Double? {
        set {
            chargeableButton?.balance = newValue
            chargeableButton?.sizeToFit()
        }

        get {
            return chargeableButton?.balance
        }
    }

    override var action: Selector? {
        didSet {
            guard let selector = action else { return }
            chargeableButton?.addTarget(self.target, action: selector, for: .touchUpInside)
        }
    }
}