//
// Created by BLACKGENE on 29/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
import Photos


public struct TransformAppParam: TypedTaskParamable {
    public typealias SourceType = Sourceable
    public typealias ConfigType = TaskConfigable

    public var sources:[SourceType]?
    public var configs:[ConfigType]?
}

public struct TransformAppResult {
    var asset: PHAsset
    var contentEditingOutput: PHContentEditingOutput
}


public class TransformEditItem: TaskConfigable {
    private (set) var transformItems = [TransformItem]()

    var hasChanges: Bool {
        return !transformItems.isEmpty //!transform.isIdentity
    }

    func addTransformItem(_ item: TransformItem) {
        transformItems.append(item)
    }

    func merge(_ editItem: TransformEditItem) {
        transformItems.append(contentsOf: editItem.transformItems)
    }

    func resetTransforms() {
        transformItems.removeAll()
    }

    var transform: CGAffineTransform {
        var t = CGAffineTransform.identity
        for transformItem in transformItems {
            t = t.concatenating(transformItem.transform)
        }
        return t
    }

    var transform3d: CATransform3D {
        var t = CATransform3DIdentity
        t.m34 = -1 / kEditItemPreviewWidth

        for transformItem in transformItems {
            t = CATransform3DConcat(t, transformItem.transform3d)
        }
        return t
    }
}

class TransformItem: NSObject {
    var transform: CGAffineTransform {
        return .identity
    }

    var transform3d: CATransform3D {
        return CATransform3DIdentity
    }
}

class RotationTransformItem: TransformItem {
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

class VerticalFlipTransformItem: TransformItem {
    override var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: 1, y: -1)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 1, 0, 0)
    }
}

class HorizontalFlipTransformItem: TransformItem {
    override var transform: CGAffineTransform {
        return CGAffineTransform(scaleX: -1, y: 1)
    }

    override var transform3d: CATransform3D {
        return CATransform3DMakeRotation(.pi, 0, 1, 0)
    }
}
