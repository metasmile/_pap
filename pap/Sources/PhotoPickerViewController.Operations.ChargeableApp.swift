//
// Created by BLACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Armchair
import DefaultsKit

/*
    TODO: make this as AppCenter.chargeManager
*/
private protocol ChargeDefaults:DefaultsProperty{
    var currentChargeType: ChargeType {set get}
    var balance: Double {set get}
}

extension Defaults: ChargeDefaults {
    fileprivate var balance: Double {
        set{
            if newValue>=0.0 && newValue<=1.0 {
                set(newValue)
            }
            assert(false,"charged balance is allowed only 0...1")
        }
        get { return get(or:0) }
    }

//    fileprivate var currentChargeType: ChargeType {
//        set{ set(newValue.rawValue) }
//        get { return ChargeType(rawValue: get(or: ChargeType.inStoreRating.rawValue))! }
//    }

    fileprivate var currentChargeType: ChargeType {
        set{ set(newValue) }
        get { return get(or: ChargeType.inStoreRating) }
    }
}

enum ChargeType:Int, Codable {
    //promotional
    case inStoreRating
    case onPromptRating
    case socialShare
    case feedback
    case ads

    //paid
    case nonConsumablePurchase
    case consumablePurchase
    case nonRenewingMonthlySubscription
    case nonRenewingYearlySubscription
    case renewableMonthlySubscription
    case renewableYearlySubscription
}

class ChargeManager {

    private var defaults: ChargeDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: ChargeManager.self)) ?? UserDefaults.standard)

    fileprivate static let `default` = ChargeManager(scheme:[
        ChargeType.inStoreRating: 0.5
        , ChargeType.onPromptRating: 0.3
        , ChargeType.socialShare: 0.2
        , ChargeType.feedback: 1
    ])

    private let scheme:[ChargeType:Double] // type: price

    init(scheme:[ChargeType:Double]){
        self.scheme = scheme
    }

    func pay(for payable: Payable){
        if let price = getPrice(for: payable){
            defaults.balance += clamp(price, 0, 1-defaults.balance)
        }
    }

    func getPrice(for payable: Payable) -> Double?{
        return scheme[payable.type]
    }

    func isCharged(for payable:Payable) -> Bool{
        return getPrice(for: payable) ?? 0 > defaults.balance
    }

    var balance:Double{
        return defaults.balance
    }

    //TODO: balance consumption
    //TODO: consumption unit date, app use count etc.
}

protocol Payable {
    var type: ChargeType {get}
}

enum PhotoPickerViewControllerRightBarButtonState {
    case unpaidDeselected
    case paidSelected
}

private class PhotoPickerViewControllerChargeableAssets {
    static let shared: PhotoPickerViewControllerChargeableAssets = PhotoPickerViewControllerChargeableAssets()

    fileprivate lazy var inStoreRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var onPromptRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var socialShareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)

    fileprivate lazy var feedbackButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
}

extension PhotoPickerViewController{

    @discardableResult
    func updateRightButtonState() -> PhotoPickerViewControllerRightBarButtonState {
        if self.estimatedAvailableSelectedItems <= 0 {

            let rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.inStoreRatingButton
//            switch Defaults.shared.chargeablePhase {
//                case .inStoreRating:
//                    rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.inStoreRatingButton
//                case .onPromptRating:
//                    rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.onPromptRatingButton
//                case .socialShare:
//                    rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.socialShareButton
//                case .feedback:
//                    rightButtonItem = PhotoPickerViewControllerChargeableAssets.shared.feedbackButton
//                default:
//                    break
//            }

            rightButtonItem.target = self
            rightButtonItem.action = #selector(self.chargeableButtonDidTap)
            navigationItem.setRightBarButton(rightButtonItem, animated: true)
            return .unpaidDeselected
        }

        navigationItem.setRightBarButton(self.doneButton, animated: true)
        return .paidSelected
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
        
        switch Defaults.shared.currentChargeType {
            case .inStoreRating:
                self.chargeableButtonDidTap_inStoreRating()
            case .onPromptRating:
                self.chargeableButtonDidTap_onPromptRating()
            case .socialShare:
                self.chargeableButtonDidTap_socialShare()
            case .feedback:
                self.chargeableButtonDidTap_feedback()
            default: break
        }
    }

    private func shiftNextChargeablePhase(){
        let nextPhase: ChargeType

        if let isRatedCurrentVersion = Armchair.userDefaultsObject()?.boolForKey(keyForArmchairKeyType(ArmchairKey.RatedCurrentVersion)), isRatedCurrentVersion {
            switch Defaults.shared.currentChargeType {
                case .inStoreRating:
                    nextPhase = .onPromptRating
                case .onPromptRating:
                    nextPhase = .socialShare
                case .socialShare:
                    nextPhase = .feedback
                case .feedback:
                    nextPhase = .feedback
                default:
                    nextPhase = .feedback
                    break
            }
        }else{
            nextPhase = .inStoreRating
        }

        Defaults.shared.currentChargeType = nextPhase
        self.updateRightButtonState()
    }

    private func chargeableButtonDidTap_inStoreRating() {
        Armchair.onDidDismissModalView { b in
            self.shiftNextChargeablePhase()
            Armchair.onDidDismissModalView(nil)
        }
        Armchair.rateApp()
    }

    private func chargeableButtonDidTap_onPromptRating() {
        Armchair.showPrompt { info in
            self.shiftNextChargeablePhase()
            return true
        }
    }

    private func chargeableButtonDidTap_socialShare() {
    }

    private func chargeableButtonDidTap_feedback() {
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
