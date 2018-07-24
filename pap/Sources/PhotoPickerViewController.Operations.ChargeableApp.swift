//
// Created by BL?ACKGENE on 19.07.18.
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

enum RewardType:Int, Codable {
    case timeOfUses
    case countOfUses
    case owned
}

typealias ChargeableObject = Chargeable & ChargeableDisplayInfo

struct ChargeableItem:Chargeable{
    let type: ChargeType
    let reward: RewardType
}

protocol Chargeable {
    var type: ChargeType {get}
    var reward:RewardType {get}
}

extension Chargeable{
    func isEqual(other:Chargeable) -> Bool{
        return reward==other.reward && type==other.type
    }
}

protocol ChargeableDisplayInfo {
    var title:String {get}
    var description:String? {get}
}

fileprivate protocol _Chargeable {
    var price:Double {get}
}

fileprivate struct ChargeSchemeItem: Chargeable, _Chargeable, ChargeableDisplayInfo {
    let type: ChargeType
    let price:Double
    let reward: RewardType
    let title: String
    let description: String?
}

protocol Payable {
    static var charge: Chargeable {get}

    func pay(_ asyncSignal:AsyncWaitSignalable) -> Bool

    init()
}

class ChargeManager:NSObject, KeyPathWatchable{

    private let payingQueue:DispatchQueue = DispatchQueue(label: String(describing: ChargeManager.self))
    private var defaults: ChargeDefaults = Defaults(userDefaults: UserDefaults(suiteName: String(describing: ChargeManager.self)) ?? UserDefaults.standard)

    fileprivate static let `default` = ChargeManager(scheme:[
        ChargeSchemeItem(type: .inStoreRating, price: 0.5, reward: .timeOfUses, title:"AppStore Rating", description:nil)
        , ChargeSchemeItem(type: .onPromptRating, price: 0.3, reward: .timeOfUses, title:"AppStore Rating", description:nil)
        , ChargeSchemeItem(type: .socialShare, price: 0.2, reward: .timeOfUses, title:"AppStore Rating", description:nil)
        , ChargeSchemeItem(type: .feedback, price: 1, reward: .timeOfUses, title:"AppStore Rating", description:nil)
    ].dictionary { (item: ChargeSchemeItem) -> ChargeType in
        return item.type
    })

    private let scheme:[ChargeType: ChargeSchemeItem] // type: price

    private init(scheme:[ChargeType: ChargeSchemeItem]){
        self.scheme = scheme
    }

    private func commitBalance(addingPrice:Double){
        defaults.balance += addingPrice
        self.balance = defaults.balance
    }

    //INFO: watchable + read-only. Don't directly access. Use commitBalance()
    @objc dynamic
    private(set) lazy var balance:Double = self.defaults.balance

    func pay(for payable: Payable.Type, _ asyncSignal:AsyncWaitSignalable=AsyncSignal()){
        if let price = getPrice(for: payable){
            let currentBalance = self.defaults.balance
            payingQueue.async{
                if payable.init().pay(asyncSignal){

                    DispatchQueue.main.async{
                        self.commitBalance(addingPrice: clamp(price, 0, 1-currentBalance))
                    }
                }
            }
        }
    }

    private func getChargeScheme(for payable: Payable.Type) -> ChargeSchemeItem?{
        return scheme.values.first { item in
            return (item as Chargeable).isEqual(other: payable.charge)
        }
    }

    func getPrice(for payable: Payable.Type) -> Double?{
        return getChargeScheme(for: payable)?.price
    }

    func getChargeInfo(for payable: Payable.Type) -> ChargeableDisplayInfo?{
        return getChargeScheme(for: payable)
    }

    func isCharged(for payable:Payable.Type) -> Bool{
        //TODO: consumption unit date, app use count etc.
        return balance > getPrice(for: payable) ?? 0
    }

    func getCharge(for payable: Payable.Type) -> ChargeableObject?{
        return getChargeScheme(for: payable)
    }

    func getRemainingCharges() -> [ChargeableObject]{
        if balance==0{
            return []
        }

        let cheapFirstItems = scheme.values.sorted { (item: ChargeSchemeItem, item2: ChargeSchemeItem) -> Bool in
            return item.price < item2.price
        }
        var remainingCharges = [ChargeSchemeItem]()
        var bal = self.balance
        for item in cheapFirstItems {
            bal += item.price
            if bal > 1{
                break
            }
            remainingCharges.append(item)
        }
        return remainingCharges
    }
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

struct Payable_InAppStoreRating:Payable{
    static let charge:Chargeable = ChargeableItem(type: .inStoreRating, reward: .timeOfUses)

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

struct Payable_OnPromptRating:Payable{
    static let charge:Chargeable = ChargeableItem(type: .onPromptRating, reward: .timeOfUses)

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

        if self.estimatedAvailableSelectedItems > 0 && ChargeManager.default.balance > 0 {
            navigationItem.setRightBarButton(self.doneButton, animated: true)
            return .paidSelected
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

        for charge in ChargeManager.default.getRemainingCharges() {
            switch charge.type {
                case .inStoreRating:
                    ChargeManager.default.pay(for: Payable_InAppStoreRating.self)
                case .onPromptRating:
                    ChargeManager.default.pay(for: Payable_InAppStoreRating.self)
                default: break
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
