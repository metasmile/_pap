//
// Created by BLACKGENE on 26/03/2018.
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


    @discardableResult
    func deselectCollectionViewItem(at indexPath: IndexPath, animated:Bool=false) -> Bool {
        if photoCollectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            photoCollectionView.deselectItem(at: indexPath, animated: animated)
            collectionView(photoCollectionView, didDeselectItemAt: indexPath)
        }

        return true
    }

    var selectedAssetsInCollectionView:[PHAsset]?{
        return photoCollectionView.indexPathsForSelectedItems?.flatMap({ PHAssets.fetched.asset(at: $0) })
    }

    func cancelAllInCurrentContext(){
        if AppCenter.default.isAppRunning {
            batchPreviewView.cancelBatchProcessing()
        }
        else {
            if AppAssets.selected.hasChanges {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Discard Changes".localized, style: .destructive, handler: { (action) in
                    self.cancelAllSelection()
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            else {
                cancelAllSelection()
            }
        }
    }

    @objc func cancelAllSelection() {
        guard let indexPaths = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in indexPaths {
            photoCollectionView.deselectItem(at: indexPath, animated: true)
        }

        batchPreviewView.removeAllCollectionViewItems()
        updateSelectedItemsTitle()
    }
}