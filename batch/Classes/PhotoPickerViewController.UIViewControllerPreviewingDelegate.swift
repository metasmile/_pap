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

            let vc = PhotoPickerDetailViewController()
            vc.asset = selectedAsset
            vc.assetItem = BatchAppAssets.shared.by(selectedAsset)
            setActions(with: selectedAsset, at: indexPath, to: vc)

            previewingContext.sourceRect = cell.frame
            return vc
        }
        else if previewingContext.sourceView == batchPreviewView {
            guard let indexPath = batchPreviewView.collectionView.indexPathForItem(at: batchPreviewView.convert(location, to: batchPreviewView.collectionView)) else { return nil }
            guard let cell = batchPreviewView.collectionView.cellForItem(at: indexPath) else { return nil }

            let selectedAssetItem = BatchAppAssets.shared.at(indexPath.item)
            let selectedAsset = selectedAssetItem.asset
            guard let selectedIndexPath = self.indexPath(of: selectedAsset) else { return nil }

            let vc = PhotoPickerDetailViewController()
            vc.asset = selectedAsset
            vc.assetItem = selectedAssetItem
            setActions(with: selectedAsset, at: selectedIndexPath, to: vc)

            previewingContext.sourceRect = batchPreviewView.collectionView.convert(cell.frame, to: batchPreviewView)
            return vc
        }
        else {
            return nil
        }
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? PhotoPickerDetailViewController {
            if let editItem = vc.assetItem {
                showPhotoEditor(with: editItem)
            }
            else {
                showPhotoEditorAndSelectIfNeeded(with: vc.asset)
            }
        }
    }

    private func setActions(with asset: PHAsset, at indexPath: IndexPath, to vc: PhotoPickerDetailViewController) {
        var typeWord = "photo"
        if asset.mediaType == .video {
            typeWord = "video"
        }

        let editAction = UIPreviewAction(title: "Edit this \(typeWord)".localizedString, style: .default) { (action, controller) in
            self.showPhotoEditorAndSelectIfNeeded(with: asset)
        }

        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            vc.actionItems = [
                UIPreviewAction(title: "Deselect this \(typeWord)".localizedString, style: .default) { action, controller in
                    self.photoCollectionView.deselectItem(at: indexPath, animated: false)
                    self.collectionView(self.photoCollectionView, didDeselectItemAt: indexPath)
                },
                editAction
            ]
        }
        else {
            vc.actionItems = [
                UIPreviewAction(title: "Select this \(typeWord)".localizedString, style: .default) { action, controller in
                    self.photoCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    self.collectionView(self.photoCollectionView, didSelectItemAt: indexPath)
                },
                editAction
            ]
        }
    }
}