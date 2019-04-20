//
// Created by BLACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol EditableApp: App {
    var defaultEditStateValue: ImageEditStateValue? { get }
    func setDefaultEditState(value: ImageEditStateValue?)
    func selectEditState(value: ImageEditStateValue?, in content: AppDockContent?)
}

extension EditableApp {
    public var defaultEditStateValue: ImageEditStateValue? { return nil }
    public func setDefaultEditState(value: ImageEditStateValue?) {}
    public func selectEditState(value: ImageEditStateValue?, in content: AppDockContent?) {}
}
