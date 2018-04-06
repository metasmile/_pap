//
// Created by BLACKGENE on 06/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIView{

    public static func performWithAnimationBarrier(_ block:() -> Void, finished:((Bool) -> Void)?=nil){
        assert(Thread.isMainThread)

        let enabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        block()
        DispatchQueue.main.async{
            UIView.setAnimationsEnabled(enabled)
            finished?(enabled)
        }
    }

    public func fade(_ duration:CFTimeInterval, forKey:String="\(#file)\(#function)\(#line)"){
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = duration
        fadeTextAnimation.type = kCATransitionFade
        self.layer.add(fadeTextAnimation, forKey: forKey)
    }
}