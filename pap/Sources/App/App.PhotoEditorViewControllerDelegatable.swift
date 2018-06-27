//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol PhotoEditorViewControllerDelegatableApp: App {
    var singleDockContent: AppDockContent? {get}
}

extension PhotoEditorViewControllerDelegatableApp {
    var singleDockContent: AppDockContent? { return nil }
}
