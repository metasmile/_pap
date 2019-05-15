//
// Copyright (c) 2019 Stells. All rights reserved.
//

import Foundation
import CoreGraphics

public protocol PhotoEditViewControllerProcessableApp: PreviewProcessableApp & PhotoEditViewControllerInteractable {
    func shouldShowPreview(item: AppAsset) -> Bool
}

extension PhotoEditViewControllerProcessableApp {
    public func previewDidTap(at normalizedPoint: CGPoint, with value: ImageEditStateValue?) {}
    public func shouldShowPreview(item: AppAsset) -> Bool { return true }
}