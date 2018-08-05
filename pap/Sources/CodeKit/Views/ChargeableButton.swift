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

struct ChargeableFillMode: OptionSet {
    public let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static let fill = ChargeableFillMode(1 << 0)
    static let opacity = ChargeableFillMode(1 << 1)
}

enum ChargeLevel: CGFloat {
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

class ChargeableImage: UIImage {
    static func `init`(balance: Double, fillMode: ChargeableFillMode = .fill, tintColor color: UIColor, appearanceDelegate: ChargeableButtonAppearance?) -> UIImage? {
        let ratio: CGFloat = CGFloat(balance)
        
        guard let iconImage = appearanceDelegate?.filledImage?.tintColor(color) else { return nil }
        
        let imageBounds = CGRect(origin: .zero, size: iconImage.size)
        return UIGraphicsImageRenderer(bounds: imageBounds).imageWithCurrentContext { (ctx) in
            if fillMode.contains(.opacity) {
                iconImage.draw(at: .zero, blendMode: .normal, alpha: ratio == 1 ? 1 : ratio / 2 + 0.1)
            }
            
            if fillMode.contains(.fill) {
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
    }
}

class ChargeableBadgeIcon: UIImage {
    static func landscapeBadgeIcon(_ image: UIImage, title: String, tintColor color: UIColor) -> UIImage {
        let attributes = [
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 10),
            NSAttributedStringKey.foregroundColor: color
        ]
        let renderText = NSString(string: "\(title)")
        let textSize = renderText.size(withAttributes: attributes)
        let badgePaddingTop: CGFloat = 2
        let badgePaddingLeft: CGFloat = 2//6
        let labelSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: textSize), UIEdgeInsets(top: -badgePaddingTop, left: -badgePaddingLeft, bottom: -badgePaddingTop, right: -badgePaddingLeft)).size
        
//        let badgeRect = CGRect(origin: .zero, size: badgeSize)
//        let roundedRectPath = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeSize.height / 2)
        
        guard let titleImage = UIGraphicsImageRenderer(size: labelSize).imageWithCurrentContext(actions: { ctx in
//            ctx.setFillColor(color.cgColor)
//            ctx.addPath(roundedRectPath.cgPath)
//            ctx.fillPath()
            
//            ctx.saveGState()
//            ctx.setBlendMode(.destinationOut)
            renderText.draw(at: CGPoint(x: badgePaddingLeft, y: badgePaddingTop), withAttributes: attributes)
//            ctx.restoreGState()
        }) else { return image }
        
        let iconSize = image.size
        let iconLeftMargin: CGFloat = badgePaddingLeft / 2
        return UIGraphicsImageRenderer(size: CGSize(width: labelSize.width + iconSize.width + iconLeftMargin, height: iconSize.height)).imageWithCurrentContext { ctx in
            image.draw(at: .zero)
            titleImage.draw(at: CGPoint(x: iconSize.width + iconLeftMargin, y: (iconSize.height - labelSize.height) / 2))
        } ?? image
    }
    
    static func portraitBadgeIcon(_ image: UIImage, title: String, tintColor color: UIColor) -> UIImage {
        let attributes = [
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 10),
            NSAttributedStringKey.foregroundColor: color
        ]
        let imageInsets = image.alignmentRectInsets
        
        let renderText = NSString(string: "\(title)")
        let textSize = renderText.size(withAttributes: attributes)
        let badgePaddingTop: CGFloat = 2
        let badgePaddingLeft: CGFloat = 2//6
        let labelSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: textSize), UIEdgeInsets(top: -badgePaddingTop, left: -badgePaddingLeft, bottom: -badgePaddingTop, right: -badgePaddingLeft)).size
        
        guard let titleImage = UIGraphicsImageRenderer(size: labelSize).imageWithCurrentContext(actions: { ctx in
            renderText.draw(at: CGPoint(x: badgePaddingLeft, y: badgePaddingTop), withAttributes: attributes)
        }) else { return image }
        
        let iconSize = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: image.size), imageInsets).size
        let scaledLabelSize = CGSize(width: iconSize.width, height: labelSize.height * (iconSize.width / labelSize.width))
        return UIGraphicsImageRenderer(size: CGSize(width: iconSize.width, height: iconSize.height + scaledLabelSize.height)).imageWithCurrentContext { ctx in
            image.draw(at: CGPoint(x: (iconSize.width - image.size.width) / 2, y: badgePaddingTop + (iconSize.height - image.size.height) / 2))
            
            titleImage.draw(in: CGRect(origin: CGPoint(x: (iconSize.width - scaledLabelSize.width) / 2, y: iconSize.height), size: scaledLabelSize))
        } ?? image
    }
}

class ChargeableButton: UIButton {
    private var appearanceDelegate: ChargeableButtonAppearance?

    convenience init(type buttonType: UIButtonType, appearance: ChargeableButtonAppearance){
        self.init(type: buttonType)
        appearanceDelegate = appearance
    }

    var fillMode: ChargeableFillMode = [.fill, .opacity]
    var showsColorLevel = true
    var showsAnimation = true
    var showsPercentage = true
    private var levelAnimations = [ChargeLevel: CAAnimation]()

    private var percentageInt:Int = Int.max {
        didSet{
            assert(percentageInt>=0 && percentageInt<=100)
        }
    }

    var normalizedValue: Double? {
        willSet {
            if let newValue = newValue{
                assert(newValue>=0 && newValue<=1,"normalizedValue is not allowed outside of 0...1")
            }
        }
        didSet {
            let normalizedValue = clamp(self.normalizedValue ?? 0,0,1)

            let ratio: CGFloat = CGFloat(normalizedValue)
            let percentageInt = Int(ratio * 100)

            guard self.percentageInt != percentageInt else{
                return
            }
            self.percentageInt = percentageInt

            let level: ChargeLevel = ChargeLevel(balance: ratio)
            let color: UIColor = showsColorLevel ? level.representativeColor ?? tintColor : tintColor

            autoreleasepool{
                var buttonImage: UIImage?
                if let iconImage = ChargeableImage(balance: normalizedValue, fillMode: self.fillMode, tintColor: color, appearanceDelegate: appearanceDelegate) {
                    if showsPercentage {
                        buttonImage = ChargeableBadgeIcon.portraitBadgeIcon(iconImage, title: String(format: "%d%%", percentageInt), tintColor: color)
                    }
                    else {
                        buttonImage = iconImage
                    }
                }

                setImage(buttonImage?.withRenderingMode(.automatic), for: .normal)
            }

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

    var normalizedValue: Double? {
        set {
            chargeableButton?.normalizedValue = newValue
            chargeableButton?.sizeToFit()
        }

        get {
            return chargeableButton?.normalizedValue
        }
    }

    override var action: Selector? {
        didSet {
            guard let selector = action else { return }
            chargeableButton?.addTarget(self.target, action: selector, for: .touchUpInside)
        }
    }
}
