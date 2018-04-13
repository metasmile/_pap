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

    public func animateAsFade(_ duration:CFTimeInterval, forKey:String="\(#file)\(#function)\(#line)"){
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = duration
        fadeTextAnimation.type = kCATransitionFade
        self.layer.add(fadeTextAnimation, forKey: forKey)
    }

    public static func animateAsSpring(_ duration: TimeInterval, delay: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: .beginFromCurrentState, animations: animations, completion: completion)
    }

    public func animateAsSpringSuperviewLayoutIfNeeded() {
        // FIXME: except for navigation bar
        if let navigationBar = self.superview?.subviews.first(where: { (view) -> Bool in
            view is UINavigationBar
        }) {
            navigationBar.layoutIfNeeded()
        }
        
        UIView.animateAsSpring(0.45, delay: 0.0, animations: { [unowned self] in
            self.superview?.layoutIfNeeded()
        }, completion: nil)
    }
}
