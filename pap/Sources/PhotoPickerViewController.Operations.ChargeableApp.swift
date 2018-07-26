//
// Created by BL?ACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Armchair

enum PhotoPickerViewControllerRightBarButtonState {
    case unpaidDeselected
    case unpaidSelected
    case paidSelected
}

extension PhotoPickerViewController{

    func initializeChargeWhenViewDidLoad(){

        AppCenter.charge.bank.watch(\.balanceValue) {
            print("Updated balance:", AppCenter.charge.bank.balanceValue)
            self.updateRightButtonState()
        }
    }

    @discardableResult
    func updateRightButtonState() -> PhotoPickerViewControllerRightBarButtonState {

        if self.estimatedAvailableSelectedItems > 0 && AppCenter.charge.bank.balanceValue > 0 {
            navigationItem.setRightBarButton(self.doneButton, animated: true)
            return .paidSelected
        }

        if self.estimatedAvailableSelectedItems > 0 && AppCenter.charge.bank.balanceValue == 0 {
            let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.chargeableButton
            rightButtonItem.title = doneButton?.title
            rightButtonItem.balance = AppCenter.charge.bank.balanceValue
            rightButtonItem.target = self
            rightButtonItem.action = #selector(self.chargeableButtonDidTap)
            navigationItem.setRightBarButton(rightButtonItem, animated: true)
            return .unpaidSelected
        }

        let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.chargeableButton
        rightButtonItem.title = nil
        rightButtonItem.balance = AppCenter.charge.bank.balanceValue
        rightButtonItem.target = self
        rightButtonItem.action = #selector(self.chargeableButtonDidTap)
        navigationItem.setRightBarButton(rightButtonItem, animated: true)
        return .unpaidDeselected
    }

    @objc fileprivate func chargeableButtonDidTap(sender: UIButton) {
//        if let vc = R.storyboard.appStoryboard.pricingViewController() {
//            vc.delegate = self
//            self.present(vc, animated: true, completion: nil)
//
//            setViewControllerDisabled(true)
//        }

        print("RemainingCharges:", AppCenter.charge.getRemainingCharges().map { $0.type })

        //TODO: users can choose the one of them
        for charge in AppCenter.charge.getRemainingCharges() {
            switch charge.type {
            case .inStoreRating:
                AppCenter.charge.pay(for: InAppStoreRating.self)
                return
            case .onPromptRating:
                AppCenter.charge.pay(for: OnPromptRating.self)
                return
            case .socialShare:
                AppCenter.charge.pay(for: OnSocialShare.self)
                return
            case .feedback:
                AppCenter.charge.pay(for: OnFeedback.self)
                return
            default:
                break
            }
        }
    }
}

extension PhotoPickerViewController: PricingViewControllerDelegate {
    func pricingViewControllerDidCancel(_ controller: PricingViewController) {
        setViewControllerDisabled(false)
    }
}


class ChargeableBarButtonItem: UIBarButtonItem {
    override init() {
        super.init()
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private lazy var chargeableButton = ChargeableButton(type: .system)
    
    private func initialize() {
        customView = chargeableButton
        
        chargeableButton.imageView?.contentMode = .scaleAspectFit
        chargeableButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        
        chargeableButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        chargeableButton.titleEdgeInsets.left = 2
        chargeableButton.titleEdgeInsets.right = -2
    }
    
    override var title: String? {
        set {
            chargeableButton.setTitle(newValue, for: .normal)
            chargeableButton.sizeToFit()
        }
        
        get {
            return chargeableButton.title(for: .normal)
        }
    }
    
    var balance: Double? {
        set {
            chargeableButton.balance = newValue
            chargeableButton.sizeToFit()
        }
        
        get {
            return chargeableButton.balance
        }
    }
    
    override var action: Selector? {
        didSet {
            guard let selector = action else { return }
            chargeableButton.addTarget(self.target, action: selector, for: .touchUpInside)
        }
    }
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
            
            guard let iconImage = R.image.systemIconFavoriteFill()?.tintColor(color) else { return }
            
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
                
                R.image.systemIconFavoriteLine()?.tintColor(UIColor.black).draw(at: .zero)
                ctx.setBlendMode(.multiply)
                R.image.systemIconFavoriteLine()?.tintColor(color).draw(at: .zero)
                
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

private class PhotoPickerViewControllerChargeableAssets {
    static let shared: PhotoPickerViewControllerChargeableAssets = PhotoPickerViewControllerChargeableAssets()

    fileprivate lazy var inStoreRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var onPromptRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var socialShareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)

    fileprivate lazy var feedbackButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
    
    fileprivate lazy var chargeableButton = ChargeableBarButtonItem()
}

private struct InAppStoreRating:Payable{
    static let charge:Chargeable = AppChargeableItem(type: .inStoreRating, reward: .timeOfUses)

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        var paid = false
        asyncSignal.begin()

        Armchair.onDidDismissModalView { b in
            paid = true
            asyncSignal.end()
            Armchair.onDidDismissModalView(nil)
        }
        DispatchQueue.main.async{
            Armchair.rateApp()
        }
        asyncSignal.waitUntilEnd()
        return paid
    }
}

private struct OnPromptRating:Payable{
    static let charge:Chargeable = AppChargeableItem(type: .onPromptRating, reward: .timeOfUses)

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        var paid = false
        asyncSignal.begin()

        DispatchQueue.main.async{
            Armchair.showPrompt { info in
                paid = true
                asyncSignal.end()
                return true
            }
        }
        asyncSignal.waitUntilEnd()
        return paid
    }
}

private struct OnSocialShare:Payable{
    static let charge:Chargeable = AppChargeableItem(type: .socialShare, reward: .timeOfUses)
    
    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        guard let appURL = URL(string: "https://get.apps.photo") else {
            return false
        }

        var paid = false
        asyncSignal.begin()
        
        DispatchQueue.main.async {
            let shareActivity = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)
            shareActivity.excludedActivityTypes = [.copyToPasteboard, .addToReadingList, .addToReminder, .addToNote]
            shareActivity.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                paid = completed
                asyncSignal.end()
            }
            UIViewController.root?.present(shareActivity, animated: true, completion: nil)
        }
        asyncSignal.waitUntilEnd()
        return paid
    }
}

extension UIActivityType {
    static let addToReminder = UIActivityType("com.apple.reminders.RemindersEditorExtension")
    static let addToNote = UIActivityType("com.apple.mobilenotes.SharingExtension")
}

import MessageUI

private class OnFeedback: NSObject, Payable, MFMailComposeViewControllerDelegate {
    static let charge:Chargeable = AppChargeableItem(type: .feedback, reward: .timeOfUses)
    
    private var mailComposerCompletionBlock: ((_ sent: Bool) -> Void)?
    
    required override init() {}
    
    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        guard MFMailComposeViewController.canSendMail() else { return false }
        
        var paid = false
        asyncSignal.begin()
        
        DispatchQueue.main.async {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["feedback@apps.photo"])
            mailComposer.setSubject("👋 My Feedback for \(Bundle.main.displayName ?? "our app") ✍️")
            
            self.mailComposerCompletionBlock = { sent in
                paid = sent
                asyncSignal.end()
            }
            UIViewController.root?.present(mailComposer, animated: true, completion: nil)
        }
        
        asyncSignal.waitUntilEnd()
        return paid
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        mailComposerCompletionBlock?(result == .sent)
        mailComposerCompletionBlock = nil
        
        controller.dismiss(animated: true, completion: nil)
    }
}
