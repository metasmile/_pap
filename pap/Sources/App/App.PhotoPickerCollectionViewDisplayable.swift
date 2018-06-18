//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// PhotoPickerCollectionView -> App
public protocol PhotoPickerCollectionViewDisplayableApp: App {
    func shouldSelect(item:AppAsset) -> Bool

    var numberOfItemsShouldSelect: Int? {get}
}

extension PhotoPickerCollectionViewDisplayableApp{
    public var numberOfItemsShouldSelect: Int? {
        return nil
    }
}