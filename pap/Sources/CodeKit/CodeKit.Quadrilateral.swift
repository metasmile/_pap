//
//  CodeKit.Quadrilateral.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 10. 8..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

struct CGQuad {
    // Start from Top Left with CLOCKWISE
    var corners : [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
    
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
    
    init(_ topLeft: CGPoint, _ topRight: CGPoint, _ bottomRight: CGPoint, _ bottomLeft: CGPoint) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }
    
    init(_ corners: [CGPoint]) {
        self.init(corners[0], corners[1], corners[2], corners[3])
    }
}
