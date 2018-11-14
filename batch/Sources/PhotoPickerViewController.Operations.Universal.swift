//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//


import Foundation
import UIKit
import Photos

//INFO: Currently, PhotoPickerViewControllerUniversalOperationsCallee is universal PhotoPickerViewController's proxy interface for all.
extension PhotoPickerViewController:PhotoPickerViewControllerUniversalOperations{
    func performInSelectionContext() {
        if let currentRightBarButtonAction = navigationItem.rightBarButtonItem?.action{
            perform(currentRightBarButtonAction, with:"")
        }else{
            assert(false, "current done button action is nil. it looks some leaked case.")
        }
    }

    func performInNonSelectionContext(performWhenAllowed:(() -> ())?=nil) {
        let chargeInCurrentContext = AppCenter.paidChargeableTypeInCurrentContext

        if let chargeInCurrentContext = chargeInCurrentContext {
            switch chargeInCurrentContext.reward{
            case .blockOfUses:
                self.openShopAppWithBlockOfUsesReward(perform:performWhenAllowed)
            default:
                performWhenAllowed?()
            }

        } else {
            self.openShopAppRequiringLicense()
        }
    }

    func selectInCurrentContext(with asset: PHAsset, animated: Bool=true) -> Bool {
        return self.selectCollectionViewItem(by: asset, scrollPosition: [.centeredVertically])
    }

    func selectInCurrentContext(at indexPath: IndexPath, animated: Bool=true) -> Bool {
        return self.selectCollectionViewItem(at: indexPath, animated: animated, scrollPosition: [.centeredVertically])
    }
}
