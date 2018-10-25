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
    func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?)
}

extension EditableApp {
    public var defaultEditStateValue: ImageEditStateValue? { return nil }
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {}
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {}
}

