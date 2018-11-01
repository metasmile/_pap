//
// Created by BLACKGENE on 2018-10-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    class func getAllSubviews<T: UIView>(view: UIView) -> [T] {
        return view.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(view: subView) as [T]
            if let view = subView as? T {
                result.append(view)
            }
            return result
        }
    }

    func getAllSubviews<T: UIView>() -> [T] {
        return UIView.getAllSubviews(view: self) as [T]
    }
}