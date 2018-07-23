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

fileprivate extension Defaults {
    fileprivate var rightButtonPayablePhase: PhotoPickerViewControllerRightBarButtonPayablePhase {
        set{ set(newValue) }
        get { return get(or: PhotoPickerViewControllerRightBarButtonPayablePhase.inStoreRating) }
    }
}

private class PhotoPickerViewControllerPayableAssets{
    static let shared: PhotoPickerViewControllerPayableAssets = PhotoPickerViewControllerPayableAssets()

    fileprivate lazy var inStoreRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var onPromptRatingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)

    fileprivate lazy var socialShareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)

    fileprivate lazy var messageUsButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
}

enum PhotoPickerViewControllerRightBarButtonState {
    case unpaidDeselected
    case paidSelected
}

enum PhotoPickerViewControllerRightBarButtonPayablePhase:Int, Codable {
    case inStoreRating // heavy
    case onPromptRating //light
    case socialShare //fucking light no share no use
    case messageUs //then, finally, you can have a permission to message us.
}

extension PhotoPickerViewController{

    func updateRightButtonState() -> PhotoPickerViewControllerRightBarButtonState {
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

        if self.estimatedAvailableSelectedItems == 0 {
            rightButtonItem.target = self
            rightButtonItem.action = #selector(self.payableButtonDidTap)
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

    private func payableButtonDidTap_inStoreRating() {

//        let ratedCurrentVersion = Armchair.userDefaultsObject()?.boolForKey(keyForArmchairKeyType(ArmchairKey.RatedCurrentVersion))

        Armchair.onDidDismissModalView { b in
            print("onDidDismissModalView",b)
        }

        Armchair.showPrompt { info in
//            info.info
            print(info.description)
            return true
        }
        Armchair.rateApp()
    }

    private func payableButtonDidTap_onPromptRating() {
    }

    private func payableButtonDidTap_socialShare() {
    }

    private func payableButtonDidTap_messageUs() {
    }
}