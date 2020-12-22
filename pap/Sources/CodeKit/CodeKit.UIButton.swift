//
// Created by BLACKGENE on 2018-09-26.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    private var loadingIndicatorTag:Int {
        return UIActivityIndicatorView.self.hash()
    }

    func startIndicating(){
        if self.superview?.viewWithTag(loadingIndicatorTag) is UIActivityIndicatorView == false{
            let loadingIndicator = UIActivityIndicatorView(style: .medium)
            loadingIndicator.hidesWhenStopped = false
            loadingIndicator.tag = loadingIndicatorTag
            self.superview?.addSubview(loadingIndicator)
            self.isHidden = true

            self.layoutIfNeeded()

            loadingIndicator.centerY = self.centerY
            loadingIndicator.centerX = self.centerX
            loadingIndicator.startAnimating()
        }
    }

    func stopIndicating(){
        if let indicatorView = self.superview?.viewWithTag(loadingIndicatorTag) as? UIActivityIndicatorView{
            self.isHidden = false

            indicatorView.stopAnimating()
            indicatorView.removeFromSuperview()
            self.layoutIfNeeded()
        }
    }
}
