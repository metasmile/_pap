//
// Copyright (c) 2019 Stells. All rights reserved.
//

import Foundation
import CoreGraphics

public protocol PhotoEditViewControllerInteractableApp {
    func previewDidTap(at normalizedPoint: CGPoint, with value: ImageEditStateValue?)
}