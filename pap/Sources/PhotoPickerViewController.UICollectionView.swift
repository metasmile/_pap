//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var collectionViewDisplayableApp:PhotoPickerCollectionViewDisplayableApp?{
        guard AppCenter.default.current is PhotoPickerCollectionViewDisplayableApp.Type else{
            return nil
        }
        return AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewDisplayableApp.self)
    }
    
    func deselectCollectionViewItems(_ items: [IndexPath], animated:Bool=false) {
        for indexPath in items {
            photoCollectionView.deselectItem(at: indexPath, animated: animated)
        }
        
        for asset in items.compactMap({ PHAssets.fetched.asset(at: $0) }) {
            AppAssets.selected.remove(for: asset)
        }
        
        batchPreviewView.reloadContent()
        updateSelectedItemUIs()
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return PHAssets.fetched.results?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return PHAssets.fetched.results?[section].count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.photoCollectionViewCell.name, for: indexPath) as! PhotoCollectionViewCell
        if let asset = PHAssets.fetched.asset(at: indexPath) {
            cell.imageContentMode = .aspectFill
            cell.setAsset(asset, at: indexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PhotoPickerFooterView", for: indexPath) as! PhotoPickerFooterView
        view.text = formattedStringForAllPhotos(at: indexPath.section)
        return view
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PHPhotoLibraryManager.cachingImageManager.startCachingImages(for: indexPaths.compactMap({ PHAssets.fetched.asset(safe: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PHPhotoLibraryManager.cachingImageManager.stopCachingImages(for: indexPaths.compactMap({ PHAssets.fetched.asset(safe: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let indexPath = initialPhotoCollectionIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            initialPhotoCollectionIndexPath = nil
        }
        
        (cell as? PhotoCollectionViewCell)?.isEnabled = self.collectionView(collectionView, shouldSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard !AppCenter.default.isAppRunning else { return false }

        if let collectableApp = collectionViewDisplayableApp
            , let asset = PHAssets.fetched.asset(at: indexPath)
            , let item = AppAssets.selected.at(unsafeIndex:indexPath.item) ?? AppAsset.create(for:asset) {

            if collectableApp.shouldSelect(item: item) == false {
                return false
            }

            if let allowedNumberOfItems = collectableApp.numberOfItemsShouldSelect
                , let selectedItems = collectionView.indexPathsForSelectedItems{

                if selectedItems.count > allowedNumberOfItems{
                    return selectedItems[0..<allowedNumberOfItems].contains(indexPath)
                } else if selectedItems.count == allowedNumberOfItems{
                    return selectedItems.contains(indexPath)
                }
            }
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard !AppCenter.default.isAppRunning else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateSelectedItemUIs()

        if let asset = PHAssets.fetched.asset(at: indexPath){
            batchPreviewView.appendCollectionViewItem(with:asset)
            
            if let app = AppCenter.default.currentInstanceAs(AutoAdjustmentApp.self), let value = app.config?.filter {
                AppAssets.selected.appendValue(value)
            }
        }

        if let _ = collectionViewDisplayableApp?.numberOfItemsShouldSelect{
            updateVisiblePhotoCollectionCellsEnabled()
        }
    }

    func collectionView(_ collectu8uionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        batchPreviewView.removeCollectionViewItem(with: PHAssets.fetched.asset(at: indexPath))

        updateSelectedItemUIs()

        if let _ = collectionViewDisplayableApp?.numberOfItemsShouldSelect{
            updateVisiblePhotoCollectionCellsEnabled()
        }
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
        return PHAssets.fetched.results?[section].count == 0 ? .zero : CGSize(width: collectionView.bounds.width, height: 60)
    }
}

extension PhotoPickerViewController: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return appDockView?.isDrawerMaximized == false
    }
}

