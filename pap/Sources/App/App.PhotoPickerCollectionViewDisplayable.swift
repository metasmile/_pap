//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// PhotoPickerCollectionView -> App
protocol PhotoPickerCollectionViewDisplayableApp: App {
    func shouldSelect(item:AppAsset) -> Bool

    var numberOfItemsShouldSelect: Int? {get}

    // do filter indexPaths and return. returning nil means, does not select any items
    func shouldSelectWhenInserted(indexPaths:[IndexPath]?) -> [IndexPath]?
}

extension PhotoPickerCollectionViewDisplayableApp{
    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public func shouldSelectWhenInserted(indexPaths: [IndexPath]?) -> [IndexPath]? {
        return nil
    }
}