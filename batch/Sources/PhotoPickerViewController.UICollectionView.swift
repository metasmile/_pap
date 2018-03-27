//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return PHAssets.fetched.results?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PHAssets.fetched.results?[section].count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        if let asset = PHAssets.fetched.asset(at: indexPath) {
            cell.imageContentMode = .aspectFill
            cell.setAsset(asset, at: indexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PhotoPickerFooterView", for: indexPath) as! PhotoPickerFooterView
        view.text = formattedStringForAllPhotos
        return view
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PHPhotoLibraryManager.cachingImageManager.startCachingImages(for: indexPaths.flatMap({ PHAssets.fetched.asset(at: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PHPhotoLibraryManager.cachingImageManager.stopCachingImages(for: indexPaths.flatMap({ PHAssets.fetched.asset(at: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let indexPath = initialPhotoCollectionIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            initialPhotoCollectionIndexPath = nil
        }

        if let cell = cell as? PhotoCollectionViewCell{
            cell.isEnabled = self.collectionView(collectionView, shouldSelectItemAt: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if AppCenter.default.isAppRunning {
            return false
        }

        if let collectableApp = AppCenter.default.currentInstanceAs(ItemCollectableApp.self)
            , let asset = PHAssets.fetched.asset(at: indexPath)
            , let item = AppAssets.selected.at(unsafeIndex:indexPath.item) ?? AppAssets.selected.create(for:asset) {

            return collectableApp.isItemEnables(for: item)
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if AppCenter.default.isAppRunning {
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateSelectedItemUIs()

        if let asset = PHAssets.fetched.asset(at: indexPath){
            batchPreviewView.appendCollectionViewItem(with:asset)
        }
    }

    func collectionView(_ collectu8uionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        batchPreviewView.removeCollectionViewItem(with: PHAssets.fetched.asset(at: indexPath))

        updateSelectedItemUIs()
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let interitemSpacing = self.collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: indexPath.item)

        let gridWidth = (UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset).width - interitemSpacing * (kPhotoPickerNumberOfItemsInRow - 1)) / kPhotoPickerNumberOfItemsInRow
        return CGSize(width: gridWidth, height: gridWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
}

