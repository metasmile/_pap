//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

protocol PhotoPickerCollectionViewDelegatableCallee {
    func performInCurrentContextWithSelectedItems()

    @discardableResult
    func selectInCurrentContext(with asset: PHAsset, animated:Bool) -> Bool

    @discardableResult
    func selectInCurrentContext(at indexPath: IndexPath, animated:Bool) -> Bool
}

// PhotoPickerCollectionView -> App
protocol PhotoPickerCollectionViewDelegatableApp: App {
    func shouldSelect(item:AppAsset) -> Bool

    var numberOfItemsShouldSelect: Int? {get}

    //INFO: do filter indexPaths and return. returning nil means, does not select any items
    func shouldSelectWhenInserted(indexPaths:[IndexPath]?) -> [IndexPath]?

    //INFO: if [shouldSelectWhenInserted(indexPaths:[IndexPath]?) -> [IndexPath]?] returns nil, this method will not be called.
    func didSelectWhenInserted(callee:PhotoPickerCollectionViewDelegatableCallee, indexPaths:[IndexPath])

    //INFO: app did change -> reloaded all collections with current context -> called.
    func didLoad(callee:PhotoPickerCollectionViewDelegatableCallee)
}

extension PhotoPickerCollectionViewDelegatableApp{
    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public func shouldSelectWhenInserted(indexPaths: [IndexPath]?) -> [IndexPath]? {
        return nil
    }

    func didLoad(callee: PhotoPickerCollectionViewDelegatableCallee) {}

    func didSelectWhenInserted(callee: PhotoPickerCollectionViewDelegatableCallee, indexPaths: [IndexPath]) {}
}