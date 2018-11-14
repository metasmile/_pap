//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

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
