//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private var collectionViewDisplayableApp:PhotoPickerCollectionViewDelegatableApp?{
        guard AppCenter.default.current is PhotoPickerCollectionViewDelegatableApp.Type else{
            return nil
        }
        return AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewDelegatableApp.self)
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
        let cachingParam = self.collectionViewDefaultCachingCellImageRequestOption(collectionView, at: indexPath)

        if let asset = PHAssets.fetched.asset(at: indexPath) {
            cell.setAsset(asset, cachingOption: cachingParam, at: indexPath)
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
        self.collectionViewStartCachingImages(collectionView, at: indexPaths)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        self.collectionViewStopCachingImages(collectionView, at: indexPaths)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        scrollToBottomIfNeeded()
        
        (cell as? PhotoCollectionViewCell)?.isEnabled = self.shouldSelectPhoto(at: indexPath)
        (cell as? PhotoCollectionViewCell)?.isSelectable = self.allowSelection
    }
    
    func shouldSelectPhoto(at indexPath: IndexPath) -> Bool {
        guard !batchPreviewView.isTaskRunning else { return false }
        
        // Scope that able to handle Asset if not -> Selection will be disabled.
        if let asset = PHAssets.fetched.asset(at: indexPath)
            , let item = AppAssets.selected.by(asset) ?? AppAsset.create(for:asset){
            
            // Scope that able to customize for controlling collection view.
            if let collectableApp = collectionViewDisplayableApp {
                if collectableApp.shouldSelect(item: item) == false{
                    return false
                }
                
                if let allowedNumberOfItems = collectableApp.numberOfItemsShouldSelect
                    , let selectedItems = self.photoCollectionView.indexPathsForSelectedItems{
                    
                    if selectedItems.count > allowedNumberOfItems{
                        return selectedItems[0..<allowedNumberOfItems].contains(indexPath)
                    } else if selectedItems.count == allowedNumberOfItems{
                        return selectedItems.contains(indexPath)
                    }
                }
                return true
            }
        }
        
        return false
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard !batchPreviewView.isTaskRunning else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard !batchPreviewView.isTaskRunning else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if allowSelection && shouldSelectPhoto(at: indexPath) {
            updateUIDisplays()

            if let asset = PHAssets.fetched.asset(at: indexPath){
                batchPreviewView.appendCollectionViewItem(with:asset)

                if let app = AppCenter.default.currentInstanceAs(EditableApp.self), let value = app.defaultEditStateValue, let item = AppAssets.selected.by(asset) {
                    AppAssets.selected.appendValue(value, for: [item])
                }

                AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewDelegatableApp.self)?.didSelect(asset: asset, indexPath:indexPath, callee: self)
            }

            if let _ = collectionViewDisplayableApp?.numberOfItemsShouldSelect{
                updateVisibleCellsEnabled()
            }
        }
        else {
            collectionView.deselectItem(at: indexPath, animated: false)
            (collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell)?.isSelectable = false
            
            if let asset = PHAssets.fetched.asset(at: indexPath) {
                let item = AppAsset.create(for:asset)
                if let app = AppCenter.default.currentInstanceAs(EditableApp.self), let value = app.defaultEditStateValue {
                    item?.editState.append(value)
                }
                
                self.showPhotoEditor(with: item, animated: true)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if allowSelection {
            guard let asset = PHAssets.fetched.asset(at: indexPath) else { return }
            batchPreviewView.removeCollectionViewItems(with: [asset])

            updateUIDisplays()

            if let _ = collectionViewDisplayableApp?.numberOfItemsShouldSelect{
                updateVisibleCellsEnabled()
            }

            AppCenter.default.currentInstanceAs(PhotoPickerCollectionViewDelegatableApp.self)?.didDeselect(asset: asset, indexPath:indexPath, callee: self)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    
    var numberOfItemsInRow: CGFloat {
        let numberOfItemsInRow: CGFloat
        
        switch traitCollection.userInterfaceIdiom {
        case .pad:
            numberOfItemsInRow = 5
        default:
            numberOfItemsInRow = 4
        }
        
        return numberOfItemsInRow
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return preferredPhotoPickerCollectionItemSize
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

extension PhotoPickerViewController: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return !isViewDisabled
    }

    //TODO: consider but performace improvement is needed
//    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        enqueuePreheatingIfNeeded()
//    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // INFO: cancel scroll to bottom
        if scrollView.isTracking, scrollView.isDragging {
            needsScrollToBottom = false
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        enqueuePreheatingIfNeeded()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        enqueuePreheatingIfNeeded()
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        enqueuePreheatingIfNeeded()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        performPrefetchIfNeeded(includingCurrentVisibleItems: true)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        performPrefetchIfNeeded(includingCurrentVisibleItems: true)
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        performPrefetchIfNeeded(includingCurrentVisibleItems: true)
    }
}

