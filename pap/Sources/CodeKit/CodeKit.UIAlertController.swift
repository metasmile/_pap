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
    public func setDefaultPopoverPresentationController(sourceView:UIView?=nil){

        if let popoverPresentationController = self.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView ?? UIViewController.presentable?.view
            if let view = sourceView{
                popoverPresentationController.sourceRect = view.bounds
            }
        }
    }

    public static func actionSheet(title: String?, message: String?, sourceView:UIView?=nil) -> UIAlertController{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.setDefaultPopoverPresentationController(sourceView:sourceView)
        return alert
    }
    
    public static func alert(title: String?, message: String?, sourceView:UIView?=nil) -> UIAlertController{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.setDefaultPopoverPresentationController(sourceView:sourceView)
        return alert
    }
    
    public static var presenting:UIAlertController?{
        return UIAlertControllerPool.shared.presentingAlertViewController
    }

    @discardableResult
    public static func alert(_ message:String
            , title:String?=nil
            , buttonTitle:String="OK".localized
            , actions:[UIAlertAction]?=nil
            , textField:((UITextField) -> ())?=nil
            , sourceView:UIView?=nil
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

        for action in actions ?? []{
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { action in
            completion?(action)
            UIAlertControllerPool.shared.clear()
        }))

        UIAlertControllerPool.shared.presentingAlertViewController = alert

        if textField != nil{
            alert.addTextField(configurationHandler: textField)
        }

        alert.setDefaultPopoverPresentationController(sourceView:sourceView)

        UIViewController.present(alert, animated: true) {
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

}
