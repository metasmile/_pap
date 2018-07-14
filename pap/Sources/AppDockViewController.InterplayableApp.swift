//
// Created by BLACKGENE on ?14.07.18.
// Copyr?ight (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private extension AppDockViewController {
    func selectCurrentAppIfExist(animated: Bool = true) {
        guard let currentApp = AppCenter.default.current, let indexOfCurrentApp = appDockItems.index(where: { $0.app == currentApp }), indexOfCurrentApp != NSNotFound else { return }
        appDockView?.selectItem(at: IndexPath(item: indexOfCurrentApp, section: 0), animated: animated)
    }
}

extension AppCenter{
    @discardableResult
    func openCurrentApp(options: AppInterplayOption?=nil, animated:Bool=false) -> Bool{
        return self.openApp(identifier: AppCenter.default.current?.info.identifier ?? "", options: options, animated: animated)
    }

    @discardableResult
    func openApp(identifier:String, options: AppInterplayOption?=nil, animated:Bool=false) -> Bool{
        if identifier.trimmed.nilEmpty != nil
        , let matchedApp = AppCenter.default.apps().first(where:{ $0.info.identifier==identifier }){
            return self.openApp(matchedApp, animated: animated)
        }
        return false
    }

    @discardableResult
    private func openApp(_ app:App.Type, animated:Bool=false) -> Bool{
        guard let rootVc = UIApplication.shared.keyWindow?.rootViewController as? AppDockNavigationController
        , let appDockVc = rootVc.topViewController as? AppDockViewController else {
            return false
        }

        self.current = app
        appDockVc.selectCurrentAppIfExist(animated: animated)
        return true
    }
}