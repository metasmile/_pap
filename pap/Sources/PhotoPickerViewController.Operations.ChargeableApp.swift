//
// Created by BL?ACKGENE on 19.07.18.
// C??opyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import DefaultsKit

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

        let chargeInCurrentContext = AppCenter.paidChargeableTypeInCurrentContext
        let paidInContext = chargeInCurrentContext != nil
        
        let isOwnedUser = chargeInCurrentContext?.reward.isOwned == true

        let rightButtonItem = ChargeableBarButtonItem.make(appearance: ChargeButtonAppearance(charge: chargeInCurrentContext))
        rightButtonItem.chargeableButton?.showsPercentage = selected == false && Defaults.shared.showChargeButtonPercentageInNavigationBar
        rightButtonItem.chargeableButton?.showsColorLevel = Defaults.shared.showChargeButtonLevelColorInNavigationBar
        rightButtonItem.chargeableButton?.showsAnimation = Defaults.shared.showChargeButtonLevelColorInNavigationBar

        if selected{
            if paidInContext {
                navigationItem.setRightBarButton(self.doneButton, animated: true)

            } else {
                rightButtonItem.title = doneButton?.title
                rightButtonItem.normalizedValue = isOwnedUser ? 1 : AppCenter.charge.bank.balanceValue
                rightButtonItem.target = self
                rightButtonItem.action = #selector(self.chargeableButtonDidTap)
                navigationItem.setRightBarButton(rightButtonItem, animated: false)
            }
            
            return true
        }

        rightButtonItem.title = nil
        rightButtonItem.normalizedValue = isOwnedUser ? 1 : AppCenter.charge.bank.balanceValue
        rightButtonItem.target = self
        rightButtonItem.action = #selector(self.chargeableButtonDidTap)
        navigationItem.setRightBarButton(rightButtonItem, animated: true)
        return false
    }

    @objc fileprivate func chargeableButtonDidTap(sender: Any) {
        print("Paid Charges:", AppCenter.charge.getChargesHasReceipt().map{ $0.identifier } )
        print("Unpaid Charges:", AppCenter.charge.getChargesHasNotReceipt().map{ $0.identifier } )

        let rated = AppCenter.charge.getChargesPaid().contains { charge in
            return charge.payment.identifier == InAppPromptRatingPayment.identifier
        }

        if rated{
            var option = AppLaunchOptions()
            option.identifierToReturn = AppCenter.default.current?.info.identifier

            if AppCenter.default.openApp(identifier:ShopApp.info.identifier, options: option){
                papLog.charge.opened()
            }
        }
        else{
            AppCenter.charge.pay(for: InAppPromptRatingPayment.self)
        }
    }

    private func alertWhenChargeableButtonDidTap(){

        //selected
//        let selected = self.estimatedAvailableSelectedItems > 0
        let alert = UIAlertController.actionSheet(title: nil, message: nil)

        let title:String
        let subtitle:String
        var titleImage:UIImage?

        let allPaidCharges = AppCenter.charge.getChargesPaid()

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
    }
}
