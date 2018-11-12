//
// Created by BLACKGENE on 10/3/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController:PhotoPickerCollectionViewDelegatableCallee{
    func performInCurrentContext() {
        if let currentRightBarButtonAction = navigationItem.rightBarButtonItem?.action{
            perform(currentRightBarButtonAction, with:"")
        }else{
            assert(false, "current done button action is nil. it looks some leaked case.")
        }
    }

    func selectInCurrentContext(with asset: PHAsset, animated: Bool=true) -> Bool {
        return self.selectCollectionViewItem(by: asset, scrollPosition: [.centeredVertically])
    }

    func selectInCurrentContext(at indexPath: IndexPath, animated: Bool=true) -> Bool {
        return self.selectCollectionViewItem(at: indexPath, animated: animated, scrollPosition: [.centeredVertically])
    }
}