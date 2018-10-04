//
// Created by BLACKGENE on 19.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController{
    @discardableResult
    func selectCollectionViewItem(by asset: PHAsset, animated:Bool=false, scrollPosition: UICollectionView.ScrollPosition?=nil) -> Bool {
        guard let indexPath = PHAssets.fetched.indexPath(of: asset) else { return false }
        return selectCollectionViewItem(at: indexPath, animated:animated, scrollPosition:scrollPosition)
    }

    @discardableResult
    func selectCollectionViewItem(at indexPath: IndexPath, animated:Bool=false, scrollPosition: UICollectionView.ScrollPosition?=nil) -> Bool {
        if photoCollectionView.delegate?.collectionView!(photoCollectionView, shouldSelectItemAt: indexPath) == false {
            return false
        }
        
        photoCollectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition ?? [])
        collectionView(photoCollectionView, didSelectItemAt: indexPath)

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

    func deselectCollectionViewItems(_ items: [IndexPath], animated:Bool=false) {
        items.forEach { indexPath in
            photoCollectionView.deselectItem(at: indexPath, animated: animated)
        }

        let assets = items.compactMap { PHAssets.fetched.asset(at: $0) }
        batchPreviewView.removeCollectionViewItems(with: assets)
        
        updateUIDisplays()
    }

    func deselectAllCollectionViewItems(){
        deselectCollectionViewItems(self.photoCollectionView.indexPathsForSelectedItems ?? [])
    }

    func updateCollectionViewSelection(by asset: PHAsset, animated:Bool = false) {
        guard let indexPath = PHAssets.fetched.indexPath(of: asset) else { return }

        if photoCollectionView.delegate?.collectionView?(photoCollectionView, shouldSelectItemAt: indexPath) == false {
            deselectCollectionViewItems([indexPath])
        }
        else {
            selectCollectionViewItem(at: indexPath)
        }
    }

    var selectedAssetsInCollectionView:[PHAsset]?{
        return photoCollectionView.indexPathsForSelectedItems?.compactMap({ PHAssets.fetched.asset(at: $0) })
    }
}
