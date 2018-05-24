//
// Created by BLACKGENE on 23.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos


extension UIActivityViewController{

    public static func presentAsDefault(activityItems:[Any], excludedActivityTypes: [UIActivityType]?=nil, completionHandler:UIKit.UIActivityViewControllerCompletionWithItemsHandler?=nil){
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = completionHandler
        activityViewController.popoverPresentationController?.sourceView = UIApplication.shared.keyWindow?.rootViewController?.view

        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
}