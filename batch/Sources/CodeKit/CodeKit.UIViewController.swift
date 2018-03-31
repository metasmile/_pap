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
            let fadeTextAnimation = CATransition()
            fadeTextAnimation.duration = 0.08
            fadeTextAnimation.type = kCATransitionFade
            self.navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")

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
}