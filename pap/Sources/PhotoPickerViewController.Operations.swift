//
// Created by BLACKGENE on 26/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController{
    func cancelProcessing() {
        batchPreviewView.cancelBatchProcessing()
        
        papLog.cancelWhilePerforming()
    }

    func cancelAllInCurrentContext(){
        cancelPreheatingIfNeeded()

        if AppCenter.default.task.isRunning {
            cancelProcessing()
        }
        else {
            if AppAssets.selected.hasChanges {
                let alert = UIAlertController.actionSheet(title: nil, message: nil)
                alert.addAction(UIAlertAction(title: "Discard Changes".localized, style: .destructive, handler: { (action) in
                    self.cancelAllSelection()
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            else {
                cancelAllSelection()
            }

            papLog.cancelWhileSelecting()
        }
    }

    @objc func cancelAllSelection() {
        guard let indexPaths = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in indexPaths {
            photoCollectionView.deselectItem(at: indexPath, animated: true)
        }

        batchPreviewView.removeAllCollectionViewItems()
        updateUIDisplays()
        updateVisibleCellsEnabled()
    }
}

