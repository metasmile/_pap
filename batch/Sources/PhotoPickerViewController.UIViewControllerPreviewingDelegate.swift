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
            guard let selectedAsset = PHAssets.fetched.asset(at: indexPath) else { return nil }
            guard let cell = photoCollectionView.cellForItem(at: indexPath) else { return nil }

            guard let item = AppAsset.create(for:selectedAsset) else {
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
            guard let selectedIndexPath = PHAssets.fetched.indexPath(of: selectedAsset) else { return nil }

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

        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let vc = viewControllerToCommit as? PhotoPickerDetailViewController, let item = vc.assetItem else {
            assert(false, "what case?")
            return
        }

        showPhotoEditor(with: item)
    }

    private func setActions(with item: PHAssetItem<AppValue>, at indexPath: IndexPath, to vc: PhotoPickerDetailViewController) {
        var typeWord = "photo"
        if item.asset.mediaType == .video {
            typeWord = "video"
        }

        let editAction = UIPreviewAction(title: "Edit this \(typeWord)".localized, style: .default) { (action, controller) in

            self.showPhotoEditor(with: item)
        }

        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            vc.actionItems = [
                UIPreviewAction(title: "Deselect this \(typeWord)".localized, style: .default) { action, controller in
                    self.deselectCollectionViewItem(at:indexPath)
                },
                editAction
            ]
        }
        else {
            vc.actionItems = [
                UIPreviewAction(title: "Select this \(typeWord)".localized, style: .default) { action, controller in
                    self.selectCollectionViewItem(at: indexPath)
                },
                editAction
            ]
        }
    }
}