//
// Created by BLACKGENE on 20.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

/* The intended display orientation of the image. If present, the value
 * of this key is a CFNumberRef with the same value as defined by the
 * TIFF and Exif specifications.  That is:
 *   1  =  0th row is at the top, and 0th column is on the left.
 *   2  =  0th row is at the top, and 0th column is on the right.
 *   3  =  0th row is at the bottom, and 0th column is on the right.
 *   4  =  0th row is at the bottom, and 0th column is on the left.
 *   5  =  0th row is on the left, and 0th column is the top.
 *   6  =  0th row is on the right, and 0th column is the top.
 *   7  =  0th row is on the right, and 0th column is the bottom.
 *   8  =  0th row is on the left, and 0th column is the bottom.
 * If not present, a value of 1 is assumed. */

enum ExifOrientation: Int {
    case top0ColLeft = 1
    case top0ColRight = 2
    case bottom0ColRight = 3
    case bottom0ColLeft = 4
    case left0ColTop = 5
    case right0ColTop = 6
    case right0ColBottom = 7
    case left0ColBottom = 8
}

extension UIDeviceOrientation {
    func exifOrientation(frontFacing: Bool) -> ExifOrientation {
        let exifOrientation: ExifOrientation
        switch UIDevice.current.orientation {
            case .portraitUpsideDown:
                exifOrientation = .left0ColBottom

            case .landscapeLeft where frontFacing:
                exifOrientation = .bottom0ColRight
            case .landscapeLeft:
                exifOrientation = .top0ColLeft

            case .landscapeRight where frontFacing:
                exifOrientation = .top0ColLeft
            case .landscapeRight:
                exifOrientation = .bottom0ColRight

            default:
                exifOrientation = .right0ColTop
        }
        return exifOrientation
    }
}