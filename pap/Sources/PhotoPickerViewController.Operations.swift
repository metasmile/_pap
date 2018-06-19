//
// Created by BLACKGENE on 26/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController{

    func cancelAllInCurrentContext(){
        if AppCenter.default.task.isRunning {
            batchPreviewView.cancelBatchProcessing()

            papLog.event.cancelWhilePerforming()
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

            papLog.event.cancelWhileSelecting()
        }

        cancelPendingAutoSelectionIfNeeded()
    }

    @objc func cancelAllSelection() {
        guard let indexPaths = photoCollectionView.indexPathsForSelectedItems else { return }
        for indexPath in indexPaths {
            photoCollectionView.deselectItem(at: indexPath, animated: true)
        }

        batchPreviewView.removeAllCollectionViewItems()
        updateSelectedItemUIs()
        updateVisiblePhotoCollectionCellsEnabled()
    }
}

