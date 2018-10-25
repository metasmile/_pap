//
// Created by BLACKGENE on 2018-09-22.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

//INFO: UIFeedbackGenerator is not queue safe and since iOS 11, it forces use on only mainqueue, otherwise will be occurred crashes.

struct UIFeedback{
    static func notify(_ type:UINotificationFeedbackGenerator.FeedbackType){
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        DispatchQueue.mainAsyncIfNot {
            g.notificationOccurred(type)
        }
    }
    static func impact(_ style:UIImpactFeedbackGenerator.FeedbackStyle){
        let g = UIImpactFeedbackGenerator(style: style)
        g.prepare()
        DispatchQueue.mainAsyncIfNot {
            g.impactOccurred()
        }
    }
    static func select(){
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        DispatchQueue.mainAsyncIfNot {
            g.selectionChanged()
        }
    }
}