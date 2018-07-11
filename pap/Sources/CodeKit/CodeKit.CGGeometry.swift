//
//  Geometry.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 12..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        return lhs.applying(CGAffineTransform(scaleX: rhs, y: rhs))
    }
}
