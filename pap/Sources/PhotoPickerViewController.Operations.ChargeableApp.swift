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

private class PhotoPickerViewControllerChargeableAssets {
    static let shared: PhotoPickerViewControllerChargeableAssets = PhotoPickerViewControllerChargeableAssets()

    fileprivate lazy var inStoreRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var onPromptRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var socialShareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)

    fileprivate lazy var feedbackButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
}

private struct InAppStoreRating:Payable{
    static let charge:Chargeable = AppChargeItem(type: .inStoreRating, reward: .timeOfUses)

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
    static let charge:Chargeable = AppChargeItem(type: .onPromptRating, reward: .timeOfUses)

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
    static let charge:Chargeable = AppChargeItem(type: .socialShare, reward: .timeOfUses)
    
    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        guard let appURL = URL(string: "https://apps.photo") else { return false } //TODO: replace this with app store link
        
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
    static let charge:Chargeable = AppChargeItem(type: .feedback, reward: .timeOfUses)
    
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
            mailComposer.setSubject("Photo Apps Feedback")
            
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

extension PhotoPickerViewController{

    @discardableResult
    func updateRightButtonState() -> PhotoPickerViewControllerRightBarButtonState {

        AppCenter.chargeManager.watch(\.balance) {
            print("Modified balance:", AppCenter.chargeManager.balance)
        }

        if self.estimatedAvailableSelectedItems > 0 && AppCenter.chargeManager.balance > 0 {
            navigationItem.setRightBarButton(self.doneButton, animated: true)
            return .paidSelected
        }

        if self.estimatedAvailableSelectedItems > 0 && AppCenter.chargeManager.balance == 0 {
            let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.inStoreRatingButton
            rightButtonItem.target = self
            rightButtonItem.action = #selector(self.chargeableButtonDidTap)
            navigationItem.setRightBarButton(rightButtonItem, animated: true)
            return .unpaidSelected
        }

        let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.inStoreRatingButton
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

        print("RemainingCharges:", AppCenter.chargeManager.getRemainingCharges().map { $0.type })
        
        for charge in AppCenter.chargeManager.getRemainingCharges() {
            switch charge.type {
                case .inStoreRating:
                    AppCenter.chargeManager.pay(for: InAppStoreRating.self)
                    return
                case .onPromptRating:
                    AppCenter.chargeManager.pay(for: OnPromptRating.self)
                    return
                case .socialShare:
                    AppCenter.chargeManager.pay(for: OnSocialShare.self)
                    return
                case .feedback:
                    AppCenter.chargeManager.pay(for: OnFeedback.self)
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
