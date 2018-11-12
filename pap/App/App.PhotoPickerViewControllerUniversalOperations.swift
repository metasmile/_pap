//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

protocol PhotoPickerViewControllerUniversalOperations {

    func performInSelectionContext()

    //INFO: To avoid side-effect. someday integrate with Selection context such like "performInCurrentContext()"
    func performInNonSelectionContext(performWhenAllowed:(() -> ())?)

    @discardableResult
    func selectInCurrentContext(with asset: PHAsset, animated:Bool) -> Bool

    @discardableResult
    func selectInCurrentContext(at indexPath: IndexPath, animated:Bool) -> Bool
}
