//
// Created by BL?ACKGENE on 19.07.18.
// C??opyright (c) 2018 Stells. All rights reserved.
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

        if selected{
            if AppCenter.isPaidInCurrentContext() {
                navigationItem.setRightBarButton(self.doneButton, animated: true)

            } else {
                let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.chargeableButton
                rightButtonItem.title = doneButton?.title
                rightButtonItem.normalizedValue = AppCenter.charge.bank.balanceValue
                rightButtonItem.target = self
                rightButtonItem.action = #selector(self.chargeableButtonDidTap)
                navigationItem.setRightBarButton(rightButtonItem, animated: false)
            }
            
            return true
        }

        let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.chargeableButton
        rightButtonItem.title = nil
        rightButtonItem.normalizedValue = AppCenter.charge.bank.balanceValue
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

        print("Paid Charges:", AppCenter.charge.getChargesHasReceipt() )
        print("Unpaid Charges:", AppCenter.charge.getChargesHasNotReceipt() )

        //selected
//        let selected = self.estimatedAvailableSelectedItems > 0
        let alert = UIAlertController.actionSheet(title: nil, message: nil)

        let title:String
        let subtitle:String
        var titleImage:UIImage?

        let allPaidCharges = AppCenter.charge.getChargesHasPaid()

        let areAllChargesHasPriceAmountPaid = AppCenter.charge.areAllChargesPaid(excluding: Set([ChargeType.welcomeFreeTrial]))
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

        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel){ action in
            papLog.charge.cancelled()
        })

        if let popover =  alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        var launchOption = AppLaunchOptions()
        launchOption.identifierToReturn = AppCenter.default.current?.info.identifier

        if AppCenter.default.openApp(identifier:ShopApp.info.identifier, options: launchOption){
            papLog.charge.opened()
        }

    }
}

extension PhotoPickerViewController: PricingViewControllerDelegate {
    func pricingViewControllerDidCancel(_ controller: PricingViewController) {
        setViewControllerDisabled(false)
    }
}

private class PhotoPickerViewControllerChargeableAssets{
    static let shared: PhotoPickerViewControllerChargeableAssets = PhotoPickerViewControllerChargeableAssets()

    fileprivate lazy var inStoreRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var onPromptRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var socialShareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)

    fileprivate lazy var feedbackButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)

    fileprivate var chargeableButton:ChargeableBarButtonItem{
        for c in AppCenter.charge.getChargesHasPaid() where c.reward.isNonConsumable{
            return chargeableButtonCharging
        }
        return chargeableButtonNormal
    }

    fileprivate lazy var chargeableButtonNormal = makeChargeableBarButtonItem(appearance:normal())

    fileprivate lazy var chargeableButtonCharging = makeChargeableBarButtonItem(appearance:charging())

    private struct normal: ChargeableButtonAppearance{
        var emptyImage: UIImage? {
            return R.image.systemIconFavoriteLine()
        }
        var filledImage: UIImage? {
            return R.image.systemIconFavoriteFill()
        }
    }

    private struct charging: ChargeableButtonAppearance{
        var emptyImage: UIImage? {
            return R.image.systemIconFavoriteLineCharging()
        }
        var filledImage: UIImage? {
            return R.image.systemIconFavoriteFill()
        }
    }

    func makeChargeableBarButtonItem(appearance:ChargeableButtonAppearance) -> ChargeableBarButtonItem{
        let chargeableButton = ChargeableButton(type: .system, appearance: appearance)
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
}
