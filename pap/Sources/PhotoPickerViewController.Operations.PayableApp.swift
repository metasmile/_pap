//
// Created by BLACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Armchair

/*
    dirty policy code in here.
*/

private class PhotoPickerViewControllerPayableAssets{
    static let shared: PhotoPickerViewControllerPayableAssets = PhotoPickerViewControllerPayableAssets()

    fileprivate lazy var ratingButton = UIBarButtonItem(image: R.image.systemIconFavoriteLine(), style: .plain, target: self, action: nil)
}

enum PhotoPickerViewControllerRightBarButtonState {
    case unpaidDeselected
    case paidSelected
}

enum PhotoPickerViewControllerRightBarButtonPayablePhase:Int {
    case inAppStoreRating // heavy
    case inAppRating //light
    case socialShare //fucking light no share no use
}

extension PhotoPickerViewController{

    func updateRightButtonState() -> PhotoPickerViewControllerRightBarButtonState {

        let ratingButton = PhotoPickerViewControllerPayableAssets.shared.ratingButton

        //TODO: payableButton by state
        if self.estimatedAvailableSelectedItems == 0 {
            ratingButton.target = self
            ratingButton.action = #selector(self.payableButtonDidTap)
            navigationItem.setRightBarButton(ratingButton, animated: true)

            return .unpaidDeselected
        }

        navigationItem.setRightBarButton(self.doneButton, animated: true)
        return .paidSelected
    }

    @objc fileprivate func payableButtonDidTap(sender: UIButton) {

        let ratedCurrentVersion = Armchair.userDefaultsObject()?.boolForKey(keyForArmchairKeyType(ArmchairKey.RatedCurrentVersion))

        //https://github.com/UrbanApps/Armchair
//        Armchair.reviewMessage()
        Armchair.shouldPromptIfRated(true)
        Armchair.onDidDeclineToRate {
            print("onDidDeclineToRate")
        }
        Armchair.onDidOptToRate {
            print("onDidOptToRate")
        }
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
}