//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PHAssetItem where EditStateValueType: AppValue {}

public class AppValue: Object {
    var transform: CGAffineTransform {
        return .identity
    }
    var transform3d: CATransform3D {
        return CATransform3DIdentity
    }
}



