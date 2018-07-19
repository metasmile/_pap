//
// Created by BLACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

public protocol EditableApp: App {
    var defaultEditStateValue: ImageEditStateValue? { get }
    func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?)
    func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in dockContent: AppDockContent?)
}

extension EditableApp {
    public var defaultEditStateValue: ImageEditStateValue? { return nil }
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {}
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in dockContent: AppDockContent?) {}
}


//TODO: change to associatedType for all types
extension StateValueSet where T: ImageEditStateValue {
    var imageEditStateValue: ImageEditStateValue? {
        return self.iterator().reversed().first
    }
}

extension PHAssetItem where EditStateValueType: ImageEditStateValue {}

public class ImageEditStateValue: Object {
    var transform: CGAffineTransform {
        return .identity
    }
    var transform3d: CATransform3D {
        return CATransform3DIdentity
    }
    var ciFilter: CIFilter? {
        return nil
    }
    var stabilizationMode: ImageAlignment.StabilizationMode? {
        return nil
    }
}
