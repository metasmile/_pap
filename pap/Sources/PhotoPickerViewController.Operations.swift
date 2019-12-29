//
// Created by BLACKGENE on 26/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PhotoPickerViewController{

    func cancelAllInCurrentContext(){
        cancelPreheatingIfNeeded()
        
        if batchPreviewView.isTaskRunning {
            batchPreviewView.cancelBatchProcessing()
        }
        else {
            if AppAssets.selected.hasChanges {
                let alert = UIAlertController.actionSheet(title: nil, message: nil)
                alert.addAction(UIAlertAction(title: "Discard Changes".localized, style: .destructive, handler: { (action) in
                    self.cancelAllSelection()
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
                alert.popoverPresentationController?.barButtonItem = self.cancelButton
                present(alert, animated: true, completion: nil)
            }
            else {
                cancelAllSelection()
            }

            papLog.cancelWhileSelecting()
        }
    }

    @objc func cancelAllSelection() {
        self.isSelectionMode = false
    }
}

