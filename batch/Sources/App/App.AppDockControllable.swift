//
// Created by BLACKGENE on 23/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol AppDockControllableApp: App {
    var dockContent: AppDockContent? {get}
}

extension AppDockControllableApp {
    public var dockContent: AppDockContent? {
        let label = UILabel()
        label.text = type(of: self).info.displayName + " Control View Area"
        label.textAlignment = .center
        label.sizeToFit()

        return AppDockContentItem(view: label, preferences: nil)
    }
}
