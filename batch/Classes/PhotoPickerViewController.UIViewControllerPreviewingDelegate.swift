//
// Created by BLACKGENE on 12/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if previewingContext.sourceView == photoCollectionView {

            guard let indexPath = photoCollectionView.indexPathForItem(at: location) else { return nil }
            guard let selectedAsset = self.asset(at: indexPath) else { return nil }
                          guard let cell = photoCollectionView.cellForItem(at: indexPath) else { return nil }
1
            self.selectCollectionViewItem(by: selectedAsset)
            assert(selectedAssetsInCollectionView?.contains(selectedAsset) == true, "selectedAsset does not contain in selectedAssetsInCollectionView")

            guard let item = AppAssets.selected.by(selectedAsset) else {
                assert(false, "selectedAsset does not contain in AppAssets.selected")
                return nil
            }

            let vc = PhotoPickerDetailViewController()
            vc.assetItem = item
            setActions(with: item, at: indexPath, to: vc)

            previewingContext.sourceRect = cell.frame
            return vc
        }
        else if previewingContext.sourceView == batchPreviewView {
            guard let indexPath = batchPreviewView.collectionView.indexPathForItem(at: batchPreviewView.convert(location, to: batchPreviewView.collectionView)) else { return nil }
            guard let cell = batchPreviewView.collectionView.cellForItem(at: indexPath) else { return nil }

            let selectedAssetItem = AppAssets.selected.at(indexPath.item)
            let selectedAsset = selectedAssetItem.asset
            guard let selectedIndexPath = self.indexPath(of: selectedAsset) else { return nil }

            guard let item = AppAssets.selected.by(selectedAsset) else {
                assert(false,"[!] AppAssets and batchPreviewView.collectionView.cellForItem is not matched.")
                return nil
            }

            let vc = PhotoPickerDetailViewController()
            vc.assetItem = item
            setActions(with: item, at: selectedIndexPath, to: vc)

            previewingContext.sourceRect = batchPreviewView.collectionView.convert(cell.frame, to: batchPreviewView)
            return vc
        }
        else {
            return nil
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let vc = viewControllerToCommit as? PhotoPickerDetailViewController, let item = vc.assetItem else {
            assert(false, "what case?")
            return
        }

        selectCollectionViewItem(by:item.asset)
        showPhotoEditor(with: item)
    }

    private func setActions(with item: PHAssetItem<AppValue>, at indexPath: IndexPath, to vc: PhotoPickerDetailViewController) {
        var typeWord = "photo"
        if item.asset.mediaType == .video {
            typeWord = "video"
        }

        let editAction = UIPreviewAction(title: "Edit this \(typeWord)".localized, style: .default) { (action, controller) in
            self.selectCollectionViewItem(by: item.asset)
            self.showPhotoEditor(with: item)
        }

        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            vc.actionItems = [
                UIPreviewAction(title: "Deselect this \(typeWord)".localized, style: .default) { action, controller in
                    self.photoCollectionView.deselectItem(at: indexPath, animated: false)
                    self.collectionView(self.photoCollectionView, didDeselectItemAt: indexPath)
                },
                editAction
            ]
        }
        else {
            vc.actionItems = [
                UIPreviewAction(title: "Select this \(typeWord)".localized, style: .default) { action, controller in
                    self.photoCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    self.collectionView(self.photoCollectionView, didSelectItemAt: indexPath)
                },
                editAction
            ]
        }
    }
}