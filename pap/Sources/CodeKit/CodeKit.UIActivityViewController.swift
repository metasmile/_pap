//
// Created by BLACKGENE on 23.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos


extension UIActivityViewController{

    public static func share(activityItems:[Any], excludedActivityTypes: [UIActivity.ActivityType]?=nil, completionHandler:UIKit.UIActivityViewController.CompletionWithItemsHandler?=nil){
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = completionHandler

        DispatchQueue.main.async {
            UIViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}
