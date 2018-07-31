//
// Created by BLACKGENE on 29/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private struct UIAlertControllerPool{
    fileprivate static var shared:UIAlertControllerPool = UIAlertControllerPool()
    fileprivate var presentingAlertViewController:UIAlertController?
    fileprivate var dismissingTimer:Timer?

    mutating fileprivate func clear(){
        self.dismissingTimer?.invalidate()
        self.dismissingTimer = nil
        self.presentingAlertViewController = nil
    }
}

public extension UIAlertController{
    public static func actionSheet(title: String?, message: String?, sourceView:UIView?=nil) -> UIAlertController{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView ?? UIViewController.root?.view
            if let view = sourceView{
                popoverPresentationController.sourceRect = view.bounds
            }
        }

        return alert
    }
    
    public static func alert(title: String?, message: String?, sourceView:UIView?=nil) -> UIAlertController{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView ?? UIViewController.root?.view
            if let view = sourceView{
                popoverPresentationController.sourceRect = view.bounds
            }
        }
        
        return alert
    }

    @discardableResult
    public static func alert(_ message:String
            , title:String?=nil
            , buttonTitle:String=NSLocalizedString("OK", comment:"")
            , actions:[UIAlertAction]?=nil
            , autoDismiss:TimeInterval?=nil
            , willDismiss:(() -> Void)?=nil
            , completion:((UIAlertAction) -> Swift.Void)? = nil) -> Bool{

        if let existedAlertVC = UIAlertControllerPool.shared.presentingAlertViewController
        , existedAlertVC.isBeingPresented{
            UIAlertControllerPool.shared.clear()

            willDismiss?()
            existedAlertVC.dismiss(animated: true) {
                self.alert(message, title: title, buttonTitle: buttonTitle, autoDismiss: autoDismiss, completion: completion)
            }
            return false
        }

        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { action in
            completion?(action)
            UIAlertControllerPool.shared.clear()
        }))

        UIAlertControllerPool.shared.presentingAlertViewController = alert


        UIViewController.root?.present(alert, animated: true) {
            if let dismissInterval = autoDismiss{
                UIAlertControllerPool.shared.dismissingTimer = Timer.scheduledTimer(withTimeInterval: dismissInterval, repeats: false) { timer in

                    alert.dismiss(animated: true)
                    willDismiss?()
                    UIAlertControllerPool.shared.clear()
                }
            }
        }

        return true
    }

    var attributedTitle: NSAttributedString? {
        get {
            if self.responds(to: Selector(Constants.attributedTitleKey)) {
                return self.value(forKey: Constants.attributedTitleKey) as? NSAttributedString
            }
            return nil
        }
        set {
            if self.responds(to: Selector(Constants.attributedTitleKey)) {
                self.setValue(newValue, forKey: Constants.attributedTitleKey)
            }
        }
    }

    private struct Constants {
        static var attributedTitleKey = "image"
    }
}
