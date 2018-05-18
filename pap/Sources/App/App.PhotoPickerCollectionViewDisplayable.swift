//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

// PhotoPickerCollectionView -> App
public protocol PhotoPickerCollectionViewDisplayableApp: App {
    func shouldSelect(item:AppAsset) -> Bool
    var conformsAssetCollectionType: PHAssetCollectionSubtype? { get }
    var conformsMediaType: PHAssetMediaType? { get }

    var numberOfItemsShouldSelect: Int? {get}
}

extension PhotoPickerCollectionViewDisplayableApp{
    public var numberOfItemsShouldSelect: Int? {
        return nil
    }
    
    public var conformsAssetCollectionType: PHAssetCollectionSubtype? {
        return nil
    }
    
    public var conformsMediaType: PHAssetMediaType? {
        return nil
    }
}
