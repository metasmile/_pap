//
// Created by BLACKGENE on 14.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

public enum PHAssetUIAlertControllerAction: Int{
    case save
    case share
    case saveAndShare
}


public protocol PHAssetUIAlertControllerSynchronizablePresenter {
    var shouldDisplayAlertActions:[PHAssetUIAlertControllerAction] {get}
}

extension PHAssetUIAlertControllerSynchronizablePresenter {
    public var shouldDisplayAlertActions: [PHAssetUIAlertControllerAction] {
        return [.save, .share, .saveAndShare]
    }

    public func presentUIAlertControllerAndWait(items: [Any]?, _ asyncSignal: AsyncWaitSignalable) {
        guard let items = items else {
            return
        }
        guard let rootViewController = UIViewController.root else {
            return
        }

        func presentShareAndAsyncSignalEnd(){
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivityType.saveToCameraRoll]
            activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                asyncSignal.end()
            }
            activityViewController.popoverPresentationController?.sourceView = UIAlertControllerPreference.sharedPopoverPresentationControllerSourceView

            DispatchQueue.main.async{
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }

        let alert = UIAlertController(title: "Choose An Export Option For %d Items".localizedFormatted(items.count), message: nil, preferredStyle: .actionSheet)

        for actionType in self.shouldDisplayAlertActions {

            switch (actionType){
                case .save:
                    alert.addAction(UIAlertAction(title: "Save".localized, style: . default, handler: { action in
                        PHPhotoLibrary.shared().saveAsAnyAndWait(items: items)
                        asyncSignal.end()
                    }))

                case .share:
                    alert.addAction(UIAlertAction(title: "Share".localized, style: . default, handler: { action in
                        presentShareAndAsyncSignalEnd()
                    }))

                case .saveAndShare:
                    alert.addAction(UIAlertAction(title: "Save and Share".localized, style: . default, handler: { action in
                        PHPhotoLibrary.shared().saveAsAnyAndWait(items: items)
                        presentShareAndAsyncSignalEnd()
                    }))
            }
        }

        if alert.actions.count > 0{
            alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
                asyncSignal.end()
            }))

            asyncSignal.begin()

            DispatchQueue.main.async{
                alert.popoverPresentationController?.sourceView = UIAlertControllerPreference.sharedPopoverPresentationControllerSourceView
                rootViewController.present(alert, animated: true)
            }

            asyncSignal.waitUntilEnd()
        }
    }
}