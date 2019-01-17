//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public protocol PhotoEditorPreviewProcessableApp: PreviewProcessableApp {
    func photoEditorPreviewDidTap(at normalizedPoint: CGPoint)
}

public protocol PhotoEditorViewControllerDelegatableApp: App {
    var photoEditorDockContent: AppDockContent? {get}
    func photoEditorWillBeginProcessing()
    func photoEditorWillEndProcessing()
    
}

extension PhotoEditorViewControllerDelegatableApp {
    public var photoEditorDockContent: AppDockContent? { return nil }
    public func photoEditorWillBeginProcessing() {}
    public func photoEditorWillEndProcessing() {}
}

extension PhotoEditorPreviewProcessableApp {
    public func photoEditorPreviewDidTap(at normalizedPoint: CGPoint) {}
}
