//
// Created by BLACKGENE on 09/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    public var titleFade:String?{
        get{
            return title
        }
        set(title){
            if let title = title{
                self.navigationController?.navigationBar.animateAsFade(0.08, forKey:title)
            }
            self.title = title
        }
    }

    public var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        }
        else {
            return UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
        }
    }

    public class var root:UIViewController?{
        return UIApplication.shared.keyWindowInScenes?.rootViewController
    }

    public class var presentable:UIViewController?{
        var vc = root
        while let pvc = vc?.presentedViewController{
            vc = pvc
        }
        return vc
    }

    func addContentViewController(_ contentViewController: UIViewController) {
        self.addChild(contentViewController)
        self.view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
    }

    func removeContentViewController(_ contentViewController: UIViewController) {
        contentViewController.willMove(toParent: nil)
        contentViewController.view.removeFromSuperview()
        contentViewController.removeFromParent()
    }
    
    public class func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        viewController.setDefaultPopoverPresentationControllerIfUndefined()
        self.presentable?.present(viewController, animated: animated, completion: completion)
    }

    func setDefaultPopoverPresentationControllerIfUndefined(sourceView:UIView?=nil){
        if let popoverPresentationController = self.popoverPresentationController{
            //Check developer-defined sourceView, set default
            if popoverPresentationController.sourceView == nil{
                if let sourceView = sourceView {
                    popoverPresentationController.sourceView = sourceView
                }
                else if let sourceView = UIViewController.presentable?.view {
                    //fallback: opened in the center
                    popoverPresentationController.sourceView = sourceView
                    popoverPresentationController.permittedArrowDirections = []
                    popoverPresentationController.sourceRect = CGRect(origin: CGPoint(x: sourceView.bounds.midX, y: sourceView.bounds.midY), size: .zero)
                }
            }
        }
    }
}
