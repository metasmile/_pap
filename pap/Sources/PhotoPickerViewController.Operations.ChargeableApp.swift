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
//            if let dimmedView = (navigationController as? AppDockNavigationController)?.dimmedView{
//                UIView.transition(with: dimmedView, duration: 0.4, options: .transitionCrossDissolve, animations: {
//                    dimmedView.isHidden = false
//                }, completion: nil)
//            }
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
                default:
                    break
            }
        }
    }
}

extension PhotoPickerViewController: PricingViewControllerDelegate {
    func pricingViewControllerDidCancel(_ controller: PricingViewController) {
        if let dimmedView = (navigationController as? AppDockNavigationController)?.dimmedView{
            UIView.transition(with: dimmedView, duration: 0.4, options: .transitionCrossDissolve, animations: {
                dimmedView.isHidden = true
            }, completion: nil)
        }
    }
}
