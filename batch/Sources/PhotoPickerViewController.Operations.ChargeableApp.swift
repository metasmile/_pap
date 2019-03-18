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
        return "\(fileName())_chargeObservingTimer"
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
        
        self.doneButton.setTitleTextAttributes(nil, for: .normal)

        if selected {

            if let chargeInCurrentContext = chargeInCurrentContext {

                switch chargeInCurrentContext.reward{
                    case .blockOfUses:
                        self.doneButton.action = #selector(self.doneButtonDidTapWhereRewardIsBlockOfUses)
                    default:
                        if let color = AppCenter.default.current?.info.themeColor {
                            self.doneButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: color], for: .normal)
                        }
                        self.doneButton.action = #selector(self.doneButtonDidTap)
                }

                navigationItem.setRightBarButtonItems([self.doneButton], animated: true)

            } else {
                let rightButtonItem = ChargeableBarButtonItem.make(appearance: ChargeButtonAppearance(charge: chargeInCurrentContext))
                rightButtonItem.title = doneButton.title
                rightButtonItem.normalizedValue = balanceValue
                rightButtonItem.target = self
                rightButtonItem.action = #selector(self.chargeableButtonDidTapWhenSelected)
                navigationItem.setRightBarButtonItems([rightButtonItem], animated: false)
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
        
        var barButtonItems = [UIBarButtonItem]()
        if !self.allowSelection {
            barButtonItems.append(UIBarButtonItem(title: "Select".localized, style: .plain, target: self, action: #selector(self.selectButtonDidTap)))
        }
        barButtonItems.append(rightButtonItem)
        
        navigationItem.setRightBarButtonItems(barButtonItems, animated: false)

        return self.allowSelection && selected
    }
    
    @objc fileprivate func selectButtonDidTap() {
        self.allowSelection = true
    }

    @objc fileprivate func chargeableButtonDidTapWhenSelected(sender: Any) {
        self.openShopAppRequiringLicense()
    }

    @objc fileprivate func chargeableButtonDidTapWhenDeselected(sender: Any) {
        openShopAppWithNonBlockingReward()
    }

    @objc fileprivate func doneButtonDidTapWhereRewardIsBlockOfUses(sender: Any) {

        let doneButtonEnabled = self.doneButton.isEnabled

        openShopAppWithBlockOfUsesReward(willBlock: {
            self.doneButton.isEnabled = false
        }, didBlock:{
            self.doneButton.isEnabled = doneButtonEnabled
        }, perform :{
            self.doneButtonDidTap(sender: "")
        })
    }
}
