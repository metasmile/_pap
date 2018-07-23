//
// Created by BLACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Armchair
import DefaultsKit

/*
    dirty policy code in here.
*/

enum PhotoPickerViewControllerRightBarButtonState {
    case unpaidDeselected
    case paidSelected
}

fileprivate enum PayablePhaseForFree:Int {
    case inStoreRating // heavy
    case onPromptRating //light
    case socialShare //fucking light no share no use
    case messageUs //then, finally, you can have a permission to message us.
}

fileprivate protocol PayableDefaults:DefaultsProperty{
    var rightButtonPayablePhase: PayablePhaseForFree {set get}
}

extension Defaults:PayableDefaults {
    fileprivate var rightButtonPayablePhase: PayablePhaseForFree {
        set{ set(newValue.rawValue) }
        get { return PayablePhaseForFree(rawValue: get(or: PayablePhaseForFree.inStoreRating.rawValue))! }
    }
}

private class PhotoPickerViewControllerPayableAssets{
    static let shared: PhotoPickerViewControllerPayableAssets = PhotoPickerViewControllerPayableAssets()

    fileprivate lazy var inStoreRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var onPromptRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var socialShareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)

    fileprivate lazy var messageUsButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
}

extension PhotoPickerViewController{

    @discardableResult
    func updateRightButtonState() -> PhotoPickerViewControllerRightBarButtonState {
        if self.estimatedAvailableSelectedItems <= 0 {

            let rightButtonItem:UIBarButtonItem
            switch Defaults.shared.rightButtonPayablePhase{
            case .inStoreRating:
                rightButtonItem = PhotoPickerViewControllerPayableAssets.shared.inStoreRatingButton
            case .onPromptRating:
                rightButtonItem = PhotoPickerViewControllerPayableAssets.shared.onPromptRatingButton
            case .socialShare:
                rightButtonItem = PhotoPickerViewControllerPayableAssets.shared.socialShareButton
            case .messageUs:
                rightButtonItem = PhotoPickerViewControllerPayableAssets.shared.messageUsButton
            }

            rightButtonItem.target = self
            rightButtonItem.action = #selector(self.payableButtonDidTap)
            navigationItem.setRightBarButton(rightButtonItem, animated: true)
            return .unpaidDeselected
        }

        navigationItem.setRightBarButton(self.doneButton, animated: true)
        return .paidSelected
    }

    @objc fileprivate func payableButtonDidTap(sender: UIButton) {
        switch Defaults.shared.rightButtonPayablePhase{
            case .inStoreRating:
                self.payableButtonDidTap_inStoreRating()
            case .onPromptRating:
                self.payableButtonDidTap_onPromptRating()
            case .socialShare:
                self.payableButtonDidTap_socialShare()
            case .messageUs:
                self.payableButtonDidTap_messageUs()
        }
    }

    private func shiftNextPayablePhase(){
        let nextPhase: PayablePhaseForFree

        if let isRatedCurrentVersion = Armchair.userDefaultsObject()?.boolForKey(keyForArmchairKeyType(ArmchairKey.RatedCurrentVersion)), isRatedCurrentVersion {
            switch Defaults.shared.rightButtonPayablePhase{
                case .inStoreRating:
                    nextPhase = .onPromptRating
                case .onPromptRating:
                    nextPhase = .socialShare
                case .socialShare:
                    nextPhase = .messageUs
                case .messageUs:
                    nextPhase = .messageUs
            }
        }else{
            nextPhase = .inStoreRating
        }

        Defaults.shared.rightButtonPayablePhase = nextPhase
        print("shiftNextPayablePhase", nextPhase)
        self.updateRightButtonState()
    }

    private func payableButtonDidTap_inStoreRating() {
        Armchair.onDidDismissModalView { b in
            self.shiftNextPayablePhase()
            Armchair.onDidDismissModalView(nil)
        }
        Armchair.rateApp()
    }

    private func payableButtonDidTap_onPromptRating() {
        Armchair.showPrompt { info in
            self.shiftNextPayablePhase()
            return true
        }
    }

    private func payableButtonDidTap_socialShare() {
    }

    private func payableButtonDidTap_messageUs() {
    }
}