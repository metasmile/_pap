//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

// PhotoPickerCollectionView -> App
protocol PhotoPickerCollectionViewDelegatableApp: App {
    func shouldSelect(item:AppAsset) -> Bool

    var numberOfItemsShouldSelect: Int? {get}

    //INFO: do filter indexPaths and return. returning nil means, does not select any items
    func shouldSelectWhenInserted(indexPaths:[IndexPath]?) -> [IndexPath]?

    //INFO: if [shouldSelectWhenInserted(indexPaths:[IndexPath]?) -> [IndexPath]?] returns nil, this method will not be called.
    func didSelectWhenInserted(callee:PhotoPickerViewControllerUniversalOperations, indexPaths:[IndexPath])

    func didInsert(callee:PhotoPickerViewControllerUniversalOperations, indexPaths:[IndexPath])

    //INFO: app did change -> reloaded all collections with current context -> called.
    func didAppear(callee:PhotoPickerViewControllerUniversalOperations)
}

extension PhotoPickerCollectionViewDelegatableApp{
    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public func shouldSelectWhenInserted(indexPaths: [IndexPath]?) -> [IndexPath]? {
        return nil
    }

    func didInsert(callee: PhotoPickerViewControllerUniversalOperations, indexPaths: [IndexPath]) {}

    func didAppear(callee: PhotoPickerViewControllerUniversalOperations) {}

    func didSelectWhenInserted(callee: PhotoPickerViewControllerUniversalOperations, indexPaths: [IndexPath]) {}
}