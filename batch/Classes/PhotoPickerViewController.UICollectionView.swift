//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func reloadPhotos(with collectionType: PHAssetCollectionType = .smartAlbum, subtype collectionSubType: PHAssetCollectionSubtype = .smartAlbumUserLibrary) {
        self.collections = nil
        self.fetchResults = nil

        photoCollectionView.reloadData()

        let options = PHFetchOptions()

        DispatchQueue.global().async {
            self.collections = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: collectionSubType, options: nil)

            self.fetchResults = [PHFetchResult<PHAsset>]()
            self.collections?.enumerateObjects({ (collection, idx, stop) in
                let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
                self.fetchResults?.append(fetchResult)
            })

            if let numberOfSection = self.fetchResults?.count, numberOfSection > 0, let numberOfItemsInSection = self.fetchResults?[numberOfSection - 1].count, numberOfItemsInSection > 0 {
                self.initialPhotoCollectionIndexPath = IndexPath(item: numberOfItemsInSection - 1, section: numberOfSection - 1)
            }

            DispatchQueue.main.async {
                self.photoCollectionView.reloadData()
            }
        }
    }

    // MARK: - Data

    func asset(at indexPath: IndexPath) -> PHAsset? {
        return fetchResults?[indexPath.section][indexPath.item]
    }

    func indexPath(of asset: PHAsset?) -> IndexPath? {
        guard let asset = asset else { return nil }
        return fetchResults?.enumerated().flatMap({
            let item = $0.element.index(of: asset)
            guard item != NSNotFound else { return nil }
            return IndexPath(item: item, section: $0.offset)
        }).first
    }

    @objc func cancelAllSelection() {
        guard let indexPaths = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in indexPaths {
            photoCollectionView.deselectItem(at: indexPath, animated: true)
        }

        batchPreviewView.removeAllCollectionViewItems()
        updateTitleForSelectedItems()
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResults?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults?[section].count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        if let asset = asset(at: indexPath) {
            cell.imageContentMode = .aspectFill
            cell.setAsset(asset, at: indexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PhotoPickerFooterView", for: indexPath) as! PhotoPickerFooterView
        view.text = generatePhotoPickerText()
        return view
    }

    fileprivate func generatePhotoPickerText() -> String {
        var numberOfImages = 0
        var numberOfVideos = 0

        fetchResults?.forEach { fetchResult in
            numberOfImages += fetchResult.countOfAssets(with: PHAssetMediaType.image)
            numberOfVideos += fetchResult.countOfAssets(with: PHAssetMediaType.video)
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        var footerText = ""
        if numberOfImages > 0 {
            if numberOfImages == 1 {
                footerText += "%d Photo".localizedFormatted(numberOfImages.decimalStyleString)
            }
            else {
                footerText += "%d Photos".localizedFormatted(numberOfImages.decimalStyleString)
            }
        }

        if numberOfVideos > 0 {
            if numberOfImages > 0 {
                footerText += ", "
            }

            if numberOfVideos == 1 {
                footerText += "%d Video".localizedFormatted(numberOfVideos.decimalStyleString)
            }
            else {
                footerText += "%d Videos".localizedFormatted(numberOfVideos.decimalStyleString)
            }
        }

        return footerText
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PhotoManager.cachingImageManager.startCachingImages(for: indexPaths.flatMap({ self.asset(at: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let cellSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        PhotoManager.cachingImageManager.stopCachingImages(for: indexPaths.flatMap({ self.asset(at: $0) }), targetSize: cellSize, contentMode: .aspectFit, options: nil)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let indexPath = initialPhotoCollectionIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            initialPhotoCollectionIndexPath = nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if AppCenter.default.isAppRunning {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if AppCenter.default.isAppRunning {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateTitleForSelectedItems()

        if let asset = self.asset(at: indexPath){
            batchPreviewView.appendCollectionViewItem(with:asset)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        batchPreviewView.removeCollectionViewItem(with: self.asset(at: indexPath))

        updateTitleForSelectedItems()
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

// https://developer.apple.com/documentation/photos/phphotolibrarychangeobserver
extension PhotoPickerViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResults = self.fetchResults else { return }

        DispatchQueue.main.async {
            for (section, fetchResult) in fetchResults.enumerated() {
                if let changes = changeInstance.changeDetails(for: fetchResult) {
                    // Keep the new fetch result for future use.
                    self.fetchResults?[section] = changes.fetchResultAfterChanges
                    if changes.hasIncrementalChanges {
                        // If there are incremental diffs, animate them in the collection view.
                        self.photoCollectionView.performBatchUpdates({
                            // For indexes to make sense, updates must be in this order:
                            // delete, insert, reload, move
                            if let removed = changes.removedIndexes, removed.count > 0 {
                                self.photoCollectionView.deleteItems(at: removed.map { IndexPath(item: $0, section:section) })
                            }
                            if let inserted = changes.insertedIndexes, inserted.count > 0 {
                                self.photoCollectionView.insertItems(at: inserted.map { IndexPath(item: $0, section:section) })
                            }
                            if let changed = changes.changedIndexes, changed.count > 0 {
                                self.photoCollectionView.reloadItems(at: changed.map { IndexPath(item: $0, section:section) })
                            }
                            changes.enumerateMoves { fromIndex, toIndex in
                                self.photoCollectionView.moveItem(at: IndexPath(item: fromIndex, section: section), to: IndexPath(item: toIndex, section: section))
                            }
                        }, completion: { _ in
                            self.updateTitleForSelectedItems()
                            if let footer = self.photoCollectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? PhotoPickerFooterView {
                                footer.text = self.generatePhotoPickerText()
                            }
                        })
                    } else {
                        // Reload the collection view if incremental diffs are not available.
                        self.photoCollectionView.reloadData()
                        self.updateTitleForSelectedItems()
                        if let footer = self.photoCollectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).last as? PhotoPickerFooterView {
                            footer.text = self.generatePhotoPickerText()
                        }
                        break
                    }
                }
            }
        }
    }
}


