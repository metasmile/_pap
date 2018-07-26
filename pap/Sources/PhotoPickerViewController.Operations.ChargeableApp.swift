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

        print("Payable Charges In Balance:", AppCenter.charge.getChargesHasPricingInBalance().map { $0.type })
        print("Paid Charges:", AppCenter.charge.getChargesHasReceipt() )
        print("Unpaid Charges:", AppCenter.charge.getChargesHasNotReceipt() )

        //selected
        let selected = self.estimatedAvailableSelectedItems > 0

        //TODO: replace with pricingViewController
        let alert = UIAlertController.actionSheet(title: "Choose A Payable Method", message: nil)

        for charge in AppCenter.charge.charges {
            let receipt = AppCenter.charge.bank.getStoredReceipt(for: charge)

            switch charge.type {

                    // charge.reward == .nonBlockOfUses, first touch -> Immediately popup.
                case .inStoreRating where receipt == nil && !selected && charge.reward == .nonBlockOfUses:
                    AppCenter.charge.pay(for: InAppStoreRating.self)
                    return

                case .onPromptRating where receipt == nil && !selected && charge.reward == .nonBlockOfUses:
                    AppCenter.charge.pay(for: OnPromptRating.self)
                    return

                    // charge.reward == .nonBlockOfUses, second touch -> Contained by menu.
                case .inStoreRating where receipt != nil && !selected && charge.reward == .nonBlockOfUses:
                    alert.addAction(UIAlertAction(title: charge.titleApplyingReward, style: .default) { action in
                        AppCenter.charge.pay(for: InAppStoreRating.self)
                    })
                case .onPromptRating where receipt != nil && !selected && charge.reward == .nonBlockOfUses:
                    alert.addAction(UIAlertAction(title: charge.titleApplyingReward, style: .default) { action in
                        AppCenter.charge.pay(for: OnPromptRating.self)
                    })

                case .socialShare:
                    alert.addAction(UIAlertAction(title: charge.titleApplyingReward, style: .default) { action in
                        AppCenter.charge.pay(for: OnSocialShare.self)
                    })
                case .feedback:
                    alert.addAction(UIAlertAction(title: charge.titleApplyingReward, style: .default) { action in
                        AppCenter.charge.pay(for: OnFeedback.self)
                    })
                default:
                    break
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))

        UIViewController.root?.present(alert, animated: true)
    }
}

extension PhotoPickerViewController: PricingViewControllerDelegate {
    func pricingViewControllerDidCancel(_ controller: PricingViewController) {
        setViewControllerDisabled(false)
    }
}

private class PhotoPickerViewControllerChargeableAssets : ChargeableButtonAppearance{
    static let shared: PhotoPickerViewControllerChargeableAssets = PhotoPickerViewControllerChargeableAssets()

    fileprivate lazy var inStoreRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var onPromptRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var socialShareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)

    fileprivate lazy var feedbackButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
    
    fileprivate lazy var chargeableButton = makeChargeableBarButtonItem()
    
    func makeChargeableBarButtonItem() -> ChargeableBarButtonItem{
        let chargeableButton = ChargeableButton(type: .system, appearance: self)
        chargeableButton.imageView?.contentMode = .scaleAspectFit
        chargeableButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)

        chargeableButton.chargeType = [.fill]

        //TODO: apply true when some restrictful conditions (e.g. finished trial days) to induce for paying
        chargeableButton.showsColorLevel = false
        chargeableButton.showsAnimation = false

        chargeableButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        chargeableButton.titleEdgeInsets.left = 2
        chargeableButton.titleEdgeInsets.right = -2

        return ChargeableBarButtonItem(button:chargeableButton)
    }

    var emptyImage: UIImage? {
        return R.image.systemIconFavoriteLine()
    }
    var filledImage: UIImage? {
        return R.image.systemIconFavoriteFill()
    }
}

private struct InAppStoreRating:Payable{
    static let charge:Chargeable = AppChargeable(type: .inStoreRating, reward: .nonBlockOfUses)

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
    static let charge:Chargeable = AppChargeable(type: .onPromptRating, reward: .nonBlockOfUses)

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
    static let charge:Chargeable = AppChargeable(type: .socialShare, reward: .timeOfUses)
    
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
    static let charge:Chargeable = AppChargeable(type: .feedback, reward: .timeOfUses)
    
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
