//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public protocol PhotoEditViewControllerInteractable {
    func previewDidTap(at normalizedPoint: CGPoint, with value: ImageEditStateValue?)
}

public protocol PhotoEditViewControllerProcessableApp: PreviewProcessableApp & PhotoEditViewControllerInteractable {
    func shouldShowPreview(item: AppAsset) -> Bool
}

extension PhotoEditViewControllerProcessableApp {
    public func previewDidTap(at normalizedPoint: CGPoint, with value: ImageEditStateValue?) {}
    public func shouldShowPreview(item: AppAsset) -> Bool { return true }
}

public protocol PhotoEditViewControllerDelegatableApp: App {
    var editViewDockContent: AppDockContent? {get}
    func willBeginProcessing()
    func willEndProcessing()
}

extension PhotoEditViewControllerDelegatableApp {
    public var editViewDockContent: AppDockContent? { return nil }
    public func willBeginProcessing() {}
    public func willEndProcessing() {}
}
