//
// Created by BL?ACKGENE on 19.07.18.
// C??opyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import PropertyKit

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
                rightButtonItem.action = #selector(self.chargeableButtonDidTapWhenSelected)
                navigationItem.setRightBarButton(rightButtonItem, animated: false)
            }
            
            return true
        }

        let rightButtonItem = ChargeableBarButtonItem.make(appearance: ChargeButtonAppearance(charge: chargeInCurrentContext))
        let paidAsAnOwnerReward = chargeInCurrentContext?.reward.isOwned == true
                || chargeInCurrentContext?.reward.isLocalOwned == true
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
        rightButtonItem.action = #selector(self.chargeableButtonDidTapWhenDeselected)
        navigationItem.setRightBarButton(rightButtonItem, animated: false)
        return false
    }

    @objc fileprivate func chargeableButtonDidTapWhenSelected(sender: Any) {
        self.openShopAppWithLicenseRequiredMessage()
    }

    //CRITICAL: Chargeable button state control. The payment action of Charge that has a reward .nonBlockOfUses should execute before chargeable button's tap action.
    // -> Press Heart
    // -> Call each "Pay" unpaid 1-charge with reward nonBlockOfUses
    // -> if all nonBlockOfUses pay was charged, -> go to Shop
    @objc fileprivate func chargeableButtonDidTapWhenDeselected(sender: Any) {
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
                    self.openShopAppWithLicenseRequiredMessage()
                }
            }
        }
    }

    private func openShopApp(){
        guard let currentApp = AppCenter.default.current else {
            return
        }

        var option = AppLaunchOptions()
        option.identifierToReturn = currentApp.info.identifier

        var options = [AppLaunchOptionsKey:Any]()
        options[.ShopAppCallerAppType] = currentApp
        option.options = options

        if AppCenter.default.openApp(identifier:ShopApp.info.identifier, options: option){
            papLog.charge.opened()
        }
    }

    private func openShopAppWithLicenseRequiredMessage(){
        UIAlertController.alert("To use this app needs a corresponding access license. Would you like to open %@?".localizedFormatted(ShopApp.info.displayName)
                , title: "A Licence Is Required.".localized
                , buttonTitle: "Open %@".localizedFormatted(ShopApp.info.displayName)
                , cancelButtonTitle: "Cancel".localized
                , completion: { action in

            self.openShopApp()
        })
    }
}
