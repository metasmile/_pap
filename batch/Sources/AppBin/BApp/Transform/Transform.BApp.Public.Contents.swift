//
// Created by BLACKGENE on 16/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public class RotationTransformItem: ImageEditStateValue {
    var angle: CGFloat = 0

    override public var transform: CGAffineTransform {
        return CGAffineTransform(rotationAngle: angle)
    }

    override public var transform3d: CATransform3D {
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

public class VerticalFlipTransformItem: ImageEditStateValue {
    override public var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: 1, y: -1)
    }

    override public var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 1, 0, 0)
    }
}

public class HorizontalFlipTransformItem: ImageEditStateValue {
    override public var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: -1, y: 1)
    }

    override public var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 0, 1, 0)
    }
}
