//
// Created by BLACKGENE on 04.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

private final class SFSafariViewControllerDelegator: Object, KeyPathWatchable, SFSafariViewControllerDelegate{
    fileprivate var didFinish:(() -> ())?
    fileprivate var didCompleteInitialLoad:((Bool) -> ())?
    fileprivate var initialLoadDidRedirectTo:(() -> ())?

    /*! @abstract Called when the view controller is about to show UIActivityViewController after the user taps the action button.
        @param URL the URL of the web page.
        @param title the title of the web page.
        @result Returns an array of UIActivity instances that will be appended to UIActivityViewController.
     */
    func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: URL, title: String?) -> [UIActivity]{
        return []
    }

    /*! @abstract Allows you to exclude certain UIActivityTypes from the UIActivityViewController presented when the user taps the action button.
        @discussion Called when the view controller is about to show a UIActivityViewController after the user taps the action button.
        @param URL the URL of the current web page.
        @param title the title of the current web page.
        @result Returns an array of any UIActivityType that you want to be excluded from the UIActivityViewController.
     */
    @available(iOS 11.0, *)
    func safariViewController(_ controller: SFSafariViewController, excludedActivityTypesFor URL: URL, title: String?) -> [UIActivityType]{
        return []
    }


    /*! @abstract Delegate callback called when the user taps the Done button. Upon this call, the view controller is dismissed modally. */
    func safariViewControllerDidFinish(_ controller: SFSafariViewController){
        didFinish?()
    }

    /*! @abstract Invoked when the initial URL load is complete.
        @param didLoadSuccessfully YES if loading completed successfully, NO if loading failed.
        @discussion This method is invoked when SFSafariViewController completes the loading of the URL that you pass
        to its initializer. It is not invoked for any subsequent page loads in the same SFSafariViewController instance.
     */
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool){
        didCompleteInitialLoad?(didLoadSuccessfully)
    }


    /*! @abstract Called when the browser is redirected to another URL before the first page load finishes.
        @param URL The new URL to which the browser was redirected.
     */
    @available(iOS 11.0, *)
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL){
        initialLoadDidRedirectTo?()
    }
}

extension UIApplication{

    private static var delegator:SFSafariViewControllerDelegator?

    @discardableResult
    public static func openSafari(with url:URL
            , willPresent:((SFSafariViewController) -> ())?=nil
            , didPresent:(() -> ())?=nil
            , didLoad:((Bool) -> ())?=nil
            , didDismiss:(() -> ())?=nil
    ) -> Bool{

        if shared.canOpenURL(url) {

            let currentQueue = DispatchQueue.current

            if delegator == nil{
                delegator = SFSafariViewControllerDelegator()
            }

            delegator?.didCompleteInitialLoad = { succeed in
                didLoad?(succeed)
            }

            delegator?.didFinish = {
                didDismiss?()

                currentQueue.async{
                    delegator = nil
                }
            }

            let safari = SFSafariViewController(url: url)
            willPresent?(safari)
            assert(safari.delegate==nil, "Do not define delegate object at \(String(describing: willPresent))")
            safari.delegate = delegator

            DispatchQueue.main.async {
                UIViewController.root?.present(safari, animated: true, completion: didPresent)
            }
            return true
        }
        return false
    }
}