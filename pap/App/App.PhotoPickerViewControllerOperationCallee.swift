//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

protocol PhotoPickerViewControllerOperationsCallee {
    func performInCurrentSelectionContext()

    @discardableResult
    func selectInCurrentContext(with asset: PHAsset, animated:Bool) -> Bool

    @discardableResult
    func selectInCurrentContext(at indexPath: IndexPath, animated:Bool) -> Bool
}
