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
        
        //INFO: keep activity indicator in right bar button
        guard !AppCenter.default.task.isRunning else { return selected }

        let chargeInCurrentContext = AppCenter.paidChargeableTypeInCurrentContext
        let balanceValue = AppCenter.charge.bank.balanceValue

        if selected{

            if let chargeInCurrentContext = chargeInCurrentContext {

                switch chargeInCurrentContext.reward{
                    case .blockOfUses:
                        self.doneButton?.action = #selector(self.doneButtonDidTapWhereRewardIsBlockOfUses)
                    default:
                        self.doneButton?.action = #selector(self.doneButtonDidTap)
                }

                navigationItem.setRightBarButton(self.doneButton, animated: true)

            } else {
                let rightButtonItem = ChargeableBarButtonItem.make(appearance: ChargeButtonAppearance(charge: chargeInCurrentContext))
                rightButtonItem.title = doneButton?.title
                rightButtonItem.normalizedValue = balanceValue
                rightButtonItem.target = self
                rightButtonItem.action = #selector(self.chargeableButtonDidTap)
                navigationItem.setRightBarButton(rightButtonItem, animated: false)
            }
            
            return true
        }

        let rightButtonItem = ChargeableBarButtonItem.make(appearance: ChargeButtonAppearance(charge: chargeInCurrentContext))
        let paidAsAnOwnerReward = chargeInCurrentContext?.reward.isOwned == true
        if paidAsAnOwnerReward {
            rightButtonItem.chargeableButton?.showsPercentage = false
            rightButtonItem.chargeableButton?.showsColorLevel = false
            rightButtonItem.chargeableButton?.showsAnimation = false
        }else{
            rightButtonItem.chargeableButton?.showsPercentage = selected == false && Defaults.shared.showChargeButtonPercentageInNavigationBar
            rightButtonItem.chargeableButton?.showsColorLevel = Defaults.shared.showChargeButtonLevelColorInNavigationBar
            rightButtonItem.chargeableButton?.showsAnimation = Defaults.shared.showChargeButtonLevelColorInNavigationBar
        }

        rightButtonItem.title = nil
        rightButtonItem.normalizedValue = balanceValue
        rightButtonItem.target = self
        rightButtonItem.action = #selector(self.chargeableButtonDidTap)
        navigationItem.setRightBarButton(rightButtonItem, animated: false)
        return false
    }

    //CRITICAL: Chargeable button state control. The payment action of Charge that has a reward .nonBlockOfUses should execute before chargeable button's tap action.
    // -> Press Heart
    // -> Call each "Pay" unpaid 1-charge with reward nonBlockOfUses
    // -> if all nonBlockOfUses pay was charged, -> go to Shop
    @objc fileprivate func chargeableButtonDidTap(sender: Any) {
        // check rated once a version
        let unpaidChagesInNonBlockingReward = AppCenter.charge.getCharges().filter({
            return $0.reward == .nonBlockOfUses && AppCenter.charge.isPaid(payable: $0.payment) == false
        })

        if unpaidChagesInNonBlockingReward.count == 0{
            openShopApp()
            return
        }

        DispatchQueue.global(qos: .userInteractive).async{
            let signal = AsyncSignal()

            for c in unpaidChagesInNonBlockingReward {
                var breakLoop = false
                signal.begin()

                AppCenter.charge.pay(for: c.payment) { r in
                    if r {
                        breakLoop = true
                    }
                    signal.end()
                }

                signal.waitUntilEnd()

                if breakLoop{
                    break
                }
            }
        }
    }

    //CRITICAL: Normal done button state BUT, payment action of Charge that has a reward .blockOfUses should execute before done button's tap action.
    // -> Press Heart
    // -> Call each "Try" already paid 1-charge with reward blockOfUses
    // -> if found, execute else go to ShopApp
    @objc fileprivate func doneButtonDidTapWhereRewardIsBlockOfUses(sender: Any) {
        let paidChagesInBlockingReward = AppCenter.charge.getChargesPaid().filter({
            return $0.reward == .blockOfUses
        })

        let doneButtonEnabled = self.doneButton?.isEnabled ?? true
        self.doneButton?.isEnabled = false

        DispatchQueue.global(qos: .userInteractive).async{
            let signal = AsyncSignal()

            var succeedAfterTriedAtOnce = false

            for c in paidChagesInBlockingReward {
                var breakLoop = false
                signal.begin()

                AppCenter.charge.try(for: c.payment) { r in
                    if r {
                        succeedAfterTriedAtOnce = true
                        breakLoop = true
                    }
                    signal.end()
                }

                signal.waitUntilEnd()

                if breakLoop{
                    break
                }
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                self.doneButton?.isEnabled = doneButtonEnabled

                if succeedAfterTriedAtOnce {
                    self.doneButtonDidTap(sender: "")
                }else{
                    self.openShopApp()
                }
            }
        }
    }

    private func openShopApp(){
        var option = AppLaunchOptions()
        option.identifierToReturn = AppCenter.default.current?.info.identifier

        if AppCenter.default.openApp(identifier:ShopApp.info.identifier, options: option){
            papLog.charge.opened()
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

        let areAllChargesHasPriceAmountPaid = AppCenter.charge.areAllChargesPaid(excluding: Set([ChargeType.freeTrial]))
        let onlyWelcomeTutorialHasPaid = allPaidCharges.count==1 && allPaidCharges.contains { $0.type == .freeTrial }

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
