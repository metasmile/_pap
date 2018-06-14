//
// Created by BLACKGENE on 14.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

protocol PHAssetUIAlertControllerFinalizableApp: FinalizableApp{}

extension PHAssetUIAlertControllerFinalizableApp {
    public func presentFinalizingUIAlertControllerAndWait(items: [Any]?, _ asyncSignal: AsyncManualSignalable) {
        guard let items = items else {
            return
        }
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return
        }

        asyncSignal.begin()

        let alert = UIAlertController(title: "Choose An Option To Export".localized, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: items.count<=1 ? "Save".localized : "Save %d Results".localizedFormatted(items.count), style: . default, handler: { action in
            PHPhotoLibrary.shared().saveAsAny(items: items)
            asyncSignal.end()
        }))
        alert.addAction(UIAlertAction(title: items.count<=1 ? "Share".localized : "Share %d Results".localizedFormatted(items.count), style: . default, handler: { action in

            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivityType.saveToCameraRoll]
            activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                asyncSignal.end()
            }
            activityViewController.popoverPresentationController?.sourceView = rootViewController.view

            DispatchQueue.main.async{
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
            asyncSignal.end()
        }))

        DispatchQueue.main.async{
            rootViewController.present(alert, animated: true)
        }

        asyncSignal.waitUntilEnd()

    }
}