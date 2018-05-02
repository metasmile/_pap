//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// App -> PhotoPickerCollectionView
public protocol PhotoPickerCollectionViewPropagableApp: PropagableApp {
    //TODO: reload or render visible cells
}


// PhotoPickerCollectionView -> App
public protocol PhotoPickerCollectionViewDisplayableApp: App {
    func shouldSelect(item:PHAssetItem<ImageEditStateValue>) -> Bool

    var numberOfItemsShouldSelect: Int? {get}
}

extension PhotoPickerCollectionViewDisplayableApp{
    public var numberOfItemsShouldSelect: Int? {
        return nil
    }
}

