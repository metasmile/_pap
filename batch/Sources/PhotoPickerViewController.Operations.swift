//
// Created by BLACKGENE on 26/03/2018.
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


extension PhotoPickerViewController{

    func cancelAllInCurrentContext(){
        cancelPreheatingIfNeeded()

        if AppCenter.default.task.isRunning {
            batchPreviewView.cancelBatchProcessing()

            batchLog.cancelWhilePerforming()
        }
        else {
            if AppAssets.selected.hasChanges {
                let alert = UIAlertController.actionSheet(title: nil, message: nil)
                alert.addAction(UIAlertAction(title: "Discard Changes".localized, style: .destructive, handler: { (action) in
                    self.cancelAllSelection()
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            else {
                cancelAllSelection()
            }

            batchLog.cancelWhileSelecting()
        }
    }

    @objc func cancelAllSelection() {
        guard let indexPaths = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in indexPaths {
            photoCollectionView.deselectItem(at: indexPath, animated: true)
        }

        batchPreviewView.removeAllCollectionViewItems()
        updateUIDisplays()
        updateVisibleCellsEnabled()
    }
}

