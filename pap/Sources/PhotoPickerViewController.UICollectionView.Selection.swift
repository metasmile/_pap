//
// Created by BLACKGENE on 19.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController{
    @discardableResult
    func selectCollectionViewItem(by asset: PHAsset) -> Bool {
        guard let indexPath = PHAssets.fetched.indexPath(of: asset) else { return false }
        return selectCollectionViewItem(at: indexPath)
    }

    @discardableResult
    func selectCollectionViewItem(at indexPath: IndexPath, animated:Bool=false) -> Bool {
        if photoCollectionView.delegate?.collectionView!(photoCollectionView, shouldSelectItemAt: indexPath) == false {
            return false
        }

        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == false {
            photoCollectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])
            collectionView(photoCollectionView, didSelectItemAt: indexPath)
        }

        return true
    }

    public func restoreSelectionByUser(_ assetLocalIdentifiers: [String]?) {
        guard let localIdentifiers = assetLocalIdentifiers else { return }
        PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil).enumerateObjects { (asset, idx, stop) in
            self.updateCollectionViewSelection(by: asset)
        }
    }

    public func deselectCollectionViewItems(by assetLocalIdentifiers: [String]?) {
        guard let localIdentifiers = assetLocalIdentifiers else { return }
        var indexPaths = [IndexPath]()
        PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil).enumerateObjects { (asset, idx, stop) in
            guard let indexPath = PHAssets.fetched.indexPath(of: asset) else { return }
            indexPaths.append(indexPath)
        }
        self.deselectCollectionViewItems(indexPaths)
    }

    @discardableResult
    func deselectCollectionViewItem(at indexPath: IndexPath, animated:Bool=false) -> Bool {
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            photoCollectionView.deselectItem(at: indexPath, animated: animated)
            collectionView(photoCollectionView, didDeselectItemAt: indexPath)
        }

        return true
    }

    func deselectCollectionViewItems(_ items: [IndexPath], animated:Bool=false) {
        for indexPath in items {
            deselectCollectionViewItem(at: indexPath, animated: animated)
        }

        let indexPaths = items.compactMap { PHAssets.fetched.asset(at: $0) }.compactMap { self.batchPreviewView.removeCollectionViewItem(with: $0) }

        updateSelectedItemUIs()

        if let indexPath = indexPaths.last {
            batchPreviewView.scrollToNeareastItem(at: indexPath)
        }
    }

    func updateCollectionViewSelection(by asset: PHAsset, animated:Bool = false) {
        guard let indexPath = PHAssets.fetched.indexPath(of: asset) else { return }

        if photoCollectionView.delegate?.collectionView!(photoCollectionView, shouldSelectItemAt: indexPath) == false {
            deselectCollectionViewItem(at: indexPath)
        }
        else {
            selectCollectionViewItem(at: indexPath)
        }
    }

    var selectedAssetsInCollectionView:[PHAsset]?{
        return photoCollectionView.indexPathsForSelectedItems?.compactMap({ PHAssets.fetched.asset(at: $0) })
    }
}