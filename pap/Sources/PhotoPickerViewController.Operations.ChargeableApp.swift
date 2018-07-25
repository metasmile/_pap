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
        chargeableButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        
        chargeableButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
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
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        
    }
    
    var balance: Double? {
        didSet {
            if balance == 1 {
                setImage(R.image.systemIconFavoriteFill(), for: .normal)
            }
            else {
                let ratio = CGFloat(balance ?? 0)
                
                guard let fillImage = R.image.systemIconFavoriteFill()?.withRenderingMode(.alwaysTemplate) else { return }
                let imageBounds = CGRect(origin: .zero, size: fillImage.size)
                let image = UIGraphicsImageRenderer(bounds: imageBounds).imageWithCurrentContext { (ctx) in
                    
                    ctx.setFillColor(tintColor.cgColor)
                    ctx.addRect(CGRect(x: 0, y: imageBounds.height - imageBounds.height * ratio, width: imageBounds.width, height: imageBounds.height * ratio))
                    ctx.fillPath()
                    
                    if let balanceImage = ctx.makeImage(), let masking = fillImage.cgImage, let masked = masking.masking(balanceImage) {
                        ctx.draw(masked, in: imageBounds)
                    }
                    R.image.systemIconFavoriteLine()?.draw(at: .zero)
                }
                setImage(image, for: .normal)
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