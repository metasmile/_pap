//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol PhotoPickerCollectionViewDisplayableApp: App {
    func isItemEnables(for item:PHAssetItem<AppValue>) -> Bool

    var numberOfItemsShouldSelect: Int? {get}
}

extension PhotoPickerCollectionViewDisplayableApp{
    public var numberOfItemsShouldSelect: Int? {
        return nil
    }
}

