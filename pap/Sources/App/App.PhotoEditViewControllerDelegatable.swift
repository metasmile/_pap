//
// Created by BLACKGENE on 04/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public protocol PhotoEditViewControllerDelegatableApp: App {
    var editViewDockContent: AppDockContent? {get}
    func willBeginProcessing()
    func willEndProcessing()
}

extension PhotoEditViewControllerDelegatableApp {
    public func willBeginProcessing() {}
    public func willEndProcessing() {}
}
