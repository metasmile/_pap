//
// Created by BLACKGENE on 2018-10-05.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    private var loadingIndicatorTag:Int {
        return UIActivityIndicatorView.self.hash()
    }

    func startIndicating(targetSubview:UIView){
        if targetSubview.superview?.viewWithTag(loadingIndicatorTag) is UIActivityIndicatorView == false{
            let loadingIndicator = UIActivityIndicatorView(style: .gray)
            loadingIndicator.hidesWhenStopped = false
            loadingIndicator.tag = loadingIndicatorTag
            targetSubview.superview?.addSubview(loadingIndicator)
            targetSubview.isHidden = true

            self.layoutIfNeeded()

            loadingIndicator.centerY = targetSubview.centerY
            loadingIndicator.right = targetSubview.right
            loadingIndicator.startAnimating()
        }
    }

    func stopIndicating(targetSubview:UIView){
        if let indicatorView = targetSubview.superview?.viewWithTag(loadingIndicatorTag) as? UIActivityIndicatorView{
            targetSubview.isHidden = false

            indicatorView.stopAnimating()
            indicatorView.removeFromSuperview()
            self.layoutIfNeeded()
        }
    }
}
