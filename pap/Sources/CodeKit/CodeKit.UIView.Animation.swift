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

    public func animateAsFade(_ duration:CFTimeInterval, forKey:String="\(fileName())\(#function)\(#line)"){
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = duration
        fadeTextAnimation.type = CATransitionType.fade
        self.layer.add(fadeTextAnimation, forKey: forKey)
    }

    public static func animateAsSpring(_ duration: TimeInterval = 0.45, delay: TimeInterval = 0.0, options: UIView.AnimationOptions = [.beginFromCurrentState, .allowUserInteraction], animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 6.0, options: options, animations: animations, completion: completion)
    }

    public func animateAsSpringSuperviewLayoutIfNeeded(completion:((Bool) -> Void)? = nil) {
        UIView.animateAsSpring(animations: { [unowned self] in
            self.superview?.layoutIfNeeded()
        }, completion: completion)
    }
}
