//
// Created by BL?ACKGENE on 19.07.18.
// C?opyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Armchair

extension PhotoPickerViewController{

    func initializeChargeWhenViewDidLoad(){

        AppCenter.charge.bank.watch(\.balanceValue) {
            print("[i] Updated balance:", AppCenter.charge.bank.balanceValue)
            self.updateDoneButtonChargeableState()
        }
    }
    
    private var chargeObservingTimerId: String {
        return "\(#file)_chargeObservingTimer"
    }
    
    internal func registerChargeObservingTimer() {
        Timer.scheduledTimer(identifier: chargeObservingTimerId, withTimeInterval: 30, repeats: true) { timer in
            self.updateDoneButtonChargeableState()
        }
    }
    
    internal func unregisterChargeObservingTimer() {
        Timer.removeScheduledTimer(identifier: chargeObservingTimerId)
    }

    @discardableResult
    func updateDoneButtonChargeableState() -> Bool {

        let selected = self.estimatedAvailableSelectedItems > 0
        let balanceValue = AppCenter.charge.bank.balanceValue

        if selected{
            let currentSyncedBalanceValue = balanceValue

            assert(currentSyncedBalanceValue>=0, "current balance value synced with < 0")

            if currentSyncedBalanceValue > 0 {
                navigationItem.setRightBarButton(self.doneButton, animated: true)

            } else if currentSyncedBalanceValue == 0 {
                let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.chargeableButton
                rightButtonItem.title = doneButton?.title
                rightButtonItem.normalizedValue = balanceValue
                rightButtonItem.target = self
                rightButtonItem.action = #selector(self.chargeableButtonDidTap)
                navigationItem.setRightBarButton(rightButtonItem, animated: false)
            }
            
            return true
        }

        let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.chargeableButton
        rightButtonItem.title = nil
        rightButtonItem.normalizedValue = balanceValue
        rightButtonItem.target = self
        rightButtonItem.action = #selector(self.chargeableButtonDidTap)
        navigationItem.setRightBarButton(rightButtonItem, animated: true)
        return false
    }

    @objc fileprivate func chargeableButtonDidTap(sender: Any) {
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
//        let selected = self.estimatedAvailableSelectedItems > 0
        let alert = UIAlertController.actionSheet(title: nil, message: nil)

        let title:String
        let subtitle:String
        var titleImage:UIImage?

        let allPaidCharges = AppCenter.charge.getChargesHasReceiptAlsoHasPriceAmount()

        let areAllChargesHasPriceAmountPaid = AppCenter.charge.areAllChargesHasPriceAmountPaid(excludingTypes: Set([ChargeType.welcomeFreeTrial]))
        let onlyWelcomeTutorialHasPaid = allPaidCharges.count==1 && allPaidCharges.contains { $0.type == .welcomeFreeTrial }

        if onlyWelcomeTutorialHasPaid{
            title = "Welcome on %@".localizedFormatted(papStrings.name)
            subtitle = "Now Contribute And Get Free Use.".localized
            titleImage = R.image.apps_collection.name.asUIImageContentOfFile //no cache

            papLog.charge.openedInWelcomeTutorial()
        }
        else if areAllChargesHasPriceAmountPaid {
            title = "This App Is Yours.".localized
            subtitle = "Turn Your Opinion Into New Things.".localized
            titleImage = R.image.join_us.name.asUIImageContentOfFile

            papLog.charge.openedInAllPaid()
        }
        else{
            title = "Extend Period of Free Use".localized
            subtitle = "You Can Renew Them Repeatedly.".localized
            titleImage = R.image.apps_collection.name.asUIImageContentOfFile //no cache

            papLog.charge.openedInNeedToPay()
        }

        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(string: "\n", attributes: [
            NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body)
        ]))
        attributedTitle.append(NSAttributedString(string: title, attributes: [
            NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .title2)
        ]))
        alert.setValue(attributedTitle, forKey: "attributedTitle")

        alert.message = subtitle

        if let titleImage = titleImage{
            let creditCardWidth = (alert.popoverPresentationController == nil ? view.bounds.width : 320) - 45
            let creditCardSize = CGSize(width: creditCardWidth, height: creditCardWidth / 2.2 /*iphone se + no scroll*/) // credit card aspect ratio: 1.586
            let imageAction = UIAlertAction(title: "", style: .default, handler: nil)
            imageAction.accessoryImage = titleImage.crop(aspectFill: creditCardSize)?/*.rounded(radius: 10)?*/.withRenderingMode(.alwaysOriginal)
            imageAction.isEnabled = false
            alert.addAction(imageAction)
        }

        for charge in AppCenter.charge.charges {
//            let receipt = AppCenter.charge.bank.getReceipt(for: charge)
            
            var badgeImage: UIImage?
            
            let estimatedChargeableImage = ChargeableImage(balance: charge.priceAmount.value, fillMode: .fill, tintColor: view.tintColor, appearanceDelegate: PhotoPickerViewControllerChargeableAssets()).withAlignmentRectInsets(UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4))
            
            if let rewardText = charge.shortTitleWithReward {
                badgeImage = ChargeableBadgeIcon.portraitBadgeIcon(estimatedChargeableImage, title: "+\(rewardText)", tintColor: view.tintColor)
            }
            else {
                badgeImage = estimatedChargeableImage
            }

            switch charge.type {

//                    // charge.reward == .nonBlockOfUses, first touch -> Immediately popup.
//                case .inStoreRating where receipt == nil && !selected && charge.reward == .nonBlockOfUses:
//                    AppCenter.charge.pay(for: InAppStoreRating.self)
//                    return
//
//                case .onPromptRating where receipt == nil && !selected && charge.reward == .nonBlockOfUses:
//                    AppCenter.charge.pay(for: OnPromptRating.self)
//                    return


                    // charge.reward == .nonBlockOfUses, second touch -> Contained by menu.
                case .inStoreRating: //where receipt != nil && !selected && charge.reward == .nonBlockOfUses:
                    let action = UIAlertAction(title: charge.title, style: .default) { action in
                        AppCenter.charge.pay(for: InAppStoreRating.self)
                    }
                    action.accessoryImage = badgeImage
                    alert.addAction(action)
                case .onPromptRating: //where receipt != nil && !selected && charge.reward == .nonBlockOfUses:
                    let action = UIAlertAction(title: charge.title, style: .default) { action in
                        AppCenter.charge.pay(for: OnPromptRating.self)
                    }
                    action.accessoryImage = badgeImage
                    alert.addAction(action)

                case .socialShare:
                    let action = UIAlertAction(title: charge.title, style: .default) { action in
                        AppCenter.charge.pay(for: OnSocialShare.self)
                    }
                    action.accessoryImage = badgeImage
                    alert.addAction(action)
                case .feedback:
                    let action = UIAlertAction(title: charge.title, style: .default) { action in
                        AppCenter.charge.pay(for: OnFeedback.self)
                    }
                    action.accessoryImage = badgeImage
                    alert.addAction(action)
                default:
                    break
            }
        }

        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel){ action in
            papLog.charge.cancelled()
        })
        
        if let popover =  alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        UIViewController.root?.present(alert, animated: true)
        papLog.charge.opened()
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

        chargeableButton.fillMode = [.fill]

        //TODO: apply true when some restrictful conditions (e.g. finished trial days) to induce for paying
        chargeableButton.showsColorLevel = false
        chargeableButton.showsAnimation = false
        chargeableButton.showsPercentage = false

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

        var paid = false
        asyncSignal.begin()
        
        DispatchQueue.main.async {
            let shareActivity = UIActivityViewController(activityItems: [papStrings.share.messageFirst], applicationActivities: nil)
            shareActivity.excludedActivityTypes = [.copyToPasteboard, .addToReadingList, .addToReminder, .addToNote]
            shareActivity.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                paid = completed
                asyncSignal.end()
            }
            shareActivity.popoverPresentationController?.sourceView = UIViewController.root?.view
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
            mailComposer.setToRecipients([papStrings.feedback.email])
            mailComposer.setSubject("👋 " + "My Feedback on %@".localizedFormatted(papStrings.name))
            mailComposer.popoverPresentationController?.sourceView = UIViewController.root?.view
            
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
