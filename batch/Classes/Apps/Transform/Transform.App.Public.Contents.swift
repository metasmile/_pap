//
// Created by BLACKGENE on 16/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public extension StateValueSet where T: BatchAppValue {
    var transform: CGAffineTransform {
        var t = CGAffineTransform.identity

        for value in self.iterator() {
            t = t.concatenating(value.transform)
        }
        return t
    }

    var transform3d: CATransform3D {
        var t = CATransform3DIdentity
        t.m34 = -1 / kEditItemPreviewWidth

        for value in self.iterator() {
            t = CATransform3DConcat(t, value.transform3d)
        }
        return t
    }
}


public class RotationTransformItem: BatchAppValue {
    var angle: CGFloat = 0

    override var transform: CGAffineTransform {
        return CGAffineTransform(rotationAngle: angle)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(angle, 0, 0, 1)
    }

    init(degrees: CGFloat) {
        super.init()

        self.angle = degrees.degreesToRadians
    }

    init(radians: CGFloat) {
        super.init()

        self.angle = radians
    }
}

public class VerticalFlipTransformItem: BatchAppValue {
    override var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: 1, y: -1)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 1, 0, 0)
    }
}

public class HorizontalFlipTransformItem: BatchAppValue {
    override var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: -1, y: 1)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 0, 1, 0)
    }
}