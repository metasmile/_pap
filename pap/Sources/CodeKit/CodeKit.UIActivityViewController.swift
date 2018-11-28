//
// Created by BLACKGENE on 23.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos


extension UIActivityViewController{
    public static func share(activityItems:[Any], excludedActivityTypes: [UIActivity.ActivityType]?=nil, completionHandler:UIKit.UIActivityViewController.CompletionWithItemsHandler?=nil){
        DispatchQueue.mainAsyncIfNot {
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityViewController.excludedActivityTypes = excludedActivityTypes
            activityViewController.completionWithItemsHandler = completionHandler
            UIViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}
