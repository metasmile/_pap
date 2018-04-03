//
// Created by BLACKGENE on 31/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

/*
 progressBar = UIProgressView(progressViewStyle: .bar)
            progressBar.isHidden = false

            navigationVC.navigationBar.addSubview(progressBar)

            let bottomConstraint = NSLayoutConstraint(item: navigationVC.navigationBar, attribute: .bottom, relatedBy: .equal, toItem: progressBar, attribute: .bottom, multiplier: 1, constant: 1)
            let leftConstraint = NSLayoutConstraint(item: navigationVC.navigationBar, attribute: .leading, relatedBy: .equal, toItem: progressBar, attribute: .leading, multiplier: 1, constant: 0)
            let rightConstraint = NSLayoutConstraint(item: navigationVC.navigationBar, attribute: .trailing, relatedBy: .equal, toItem: progressBar, attribute: .trailing, multiplier: 1, constant: 0)

            progressBar.translatesAutoresizingMaskIntoConstraints = false
            navigationVC.view.addConstraints([bottomConstraint, leftConstraint, rightConstraint])
            */

extension UINavigationController{
    public var navigationBarProgressView: UIProgressView? {
        set {
            if let progressBar = newValue {
                self.navigationBarProgressView = nil

                progressBar.tag = self.hashValue
                self.navigationBar.addSubview(progressBar)

            }else{
                navigationBarProgressView?.removeFromSuperview()
            }
        }
        get {
            return self.navigationBar.viewWithTag(self.hashValue) as? UIProgressView
        }
    }

    public func setNeedsNavigationBarProgressViewLayoutConstraints () {
        guard let progressView = self.navigationBarProgressView else {
            return
        }

        let bottomConstraint = NSLayoutConstraint(item: navigationBar, attribute: .bottom, relatedBy: .equal, toItem: progressView, attribute: .bottom, multiplier: 1, constant: 1)
        let leftConstraint = NSLayoutConstraint(item: navigationBar, attribute: .leading, relatedBy: .equal, toItem: progressView, attribute: .leading, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: navigationBar, attribute: .trailing, relatedBy: .equal, toItem: progressView, attribute: .trailing, multiplier: 1, constant: 0)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        self.view.removeConstraints([bottomConstraint, leftConstraint, rightConstraint])
        self.view.addConstraints([bottomConstraint, leftConstraint, rightConstraint])
    }
}