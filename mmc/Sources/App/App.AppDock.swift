//
// Created by BLACKGENE on 23/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol AppDockApp: class, App {
    var content: AppDockContent? {get}

    static var fixedContentLayout:Bool {get}
}

extension AppDockApp {
    public static var fixedContentLayout: Bool {
        return false
    }

    public var content: AppDockContent? {
        let label = UILabel()
        label.text = type(of: self).info.displayName + " Control View Area"
        label.textAlignment = .center
        label.sizeToFit()

        return AppDockContentItem(view: label, preferences: nil, contentScrollable: nil)
    }
}
