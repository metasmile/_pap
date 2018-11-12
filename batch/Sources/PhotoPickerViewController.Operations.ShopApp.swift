//
// Created by BL?ACKGENE on 19.07.18.
// C??opyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import PropertyKit

extension PhotoPickerViewController{

    private func openShopApp(){
        guard let currentApp = AppCenter.default.current else {
            return
        }

        var option = AppLaunchOptions()
        option.identifierToReturn = currentApp.info.identifier

        var options = [AppLaunchOptionsKey:Any]()
        options[.ShopCallerAppType] = currentApp
        option.options = options

        if AppCenter.default.openApp(identifier:ShopApp.info.identifier, options: option){
            batchLog.charge.opened()
        }
    }

    func openShopAppWithLicenseRequiredMessage(){
        UIAlertController.alert("To use this app needs a corresponding access license. Would you like to open %@?".localizedFormatted(ShopApp.info.displayName)
                , title: "A Licence Is Required.".localized
                , buttonTitle: "Open %@".localizedFormatted(ShopApp.info.displayName)
                , cancelButtonTitle: "Cancel".localized
                , completion: { action in

            self.openShopApp()
        })
    }

    //CRITICAL: Normal done button state BUT, payment action of Charge that has a reward .blockOfUses should execute before done button's tap action.
    // -> Press Heart
    // -> Call each "Try" already paid 1-charge with reward blockOfUses
    // -> if found, execute else go to ShopApp
    func openShopAppWithBlockOfUsesReward(willBlock: (() -> ())?=nil, didBlock: (() -> ())?=nil, perform: (() -> ())?=nil){
        let paidChagesInBlockingReward = AppCenter.charge.getChargesPaid().filter({
            return $0.reward == .blockOfUses
        })

        willBlock?()

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
                didBlock?()

                if succeedAfterTriedAtOnce {
                    perform?()
                }else{
                    self.openShopAppWithLicenseRequiredMessage()
                }
            }
        }
    }

    //CRITICAL: Chargeable button state control. The payment action of Charge that has a reward .nonBlockOfUses should execute before chargeable button's tap action.
    // -> Press Heart
    // -> Call each "Pay" unpaid 1-charge with reward nonBlockOfUses
    // -> if all nonBlockOfUses pay was charged, -> go to Shop
    func openShopAppWithNonBlockingReward(){
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
}
