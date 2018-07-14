//
// Created by BLACKGENE on 14.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension AppDockViewController {
    func selectCurrentAppIfExist(animated: Bool = true) {
        guard let currentApp = AppCenter.default.current, let indexOfCurrentApp = appDockItems.index(where: { $0.app == currentApp }), indexOfCurrentApp != NSNotFound else { return }
        appDockView?.selectItem(at: IndexPath(item: indexOfCurrentApp, section: 0), animated: animated)
    }
}

extension AppCenter{
    @discardableResult
    func selectApp(_ app:App.Type, animated:Bool=false) -> Bool{
        guard let rootVc = UIApplication.shared.keyWindow?.rootViewController as? AppDockNavigationController
        , let appDockVc = rootVc.topViewController as? AppDockViewController
        , app != self.current else {
            return false
        }

        self.current = app
        appDockVc.selectCurrentAppIfExist(animated: animated)
        return true
    }
}