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

public struct UIAlertControllerPreference {
    static private var _sourceView:UIView?
    static private var _unsetWhenUse:Bool = true

    static func setSharedPopoverPresentationControllerSourceView(view:UIView?, unsetWhenUse:Bool=true) {
//        _sourceView = view
//        _unsetWhenUse = unsetWhenUse
    }

    static var sharedPopoverPresentationControllerSourceView:UIView? {
        let view = _sourceView ?? UIViewController.root?.view
        if _unsetWhenUse{
            _sourceView = nil
        }
        //TODO: convertRect? not works yet.
        return view
    }
}

public extension UIAlertController{

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

        alert.popoverPresentationController?.sourceView = UIAlertControllerPreference.sharedPopoverPresentationControllerSourceView

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
}
