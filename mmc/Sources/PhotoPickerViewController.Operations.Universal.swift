//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController:PhotoPickerViewControllerUniversalOperations{
    func performInSelectionContext() {
        if let currentRightBarButtonAction = navigationItem.rightBarButtonItem?.action{
            perform(currentRightBarButtonAction, with:"")
        }
    }

    func performInNonSelectionContext(performWhenAllowed: (() -> ())?) {
        assert(false,"Not implemented yet. (e.g. run Ads.)")
    }

    func selectInCurrentContext(with asset: PHAsset, animated: Bool=true) -> Bool {
        return self.selectCollectionViewItem(by: asset, scrollPosition: [.centeredVertically])
    }

    func selectInCurrentContext(at indexPath: IndexPath, animated: Bool=true) -> Bool {
        return self.selectCollectionViewItem(at: indexPath, animated: animated, scrollPosition: [.centeredVertically])
    }
}
