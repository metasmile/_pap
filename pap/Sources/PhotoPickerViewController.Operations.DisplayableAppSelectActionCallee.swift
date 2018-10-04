//
// Created by BLACKGENE on 10/3/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension PhotoPickerViewController:PhotoPickerCollectionViewDisplayableAppSelectActionCallee{
    func performInCurrentContextWithSelectedItems() {
        if let currentRightBarButtonAction = navigationItem.rightBarButtonItem?.action{
            perform(currentRightBarButtonAction, with:"")
        }
    }
}