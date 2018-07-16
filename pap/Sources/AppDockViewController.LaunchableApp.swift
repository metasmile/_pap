//
// Created by BLACKGENE on ?14.07.18.
// Copyr?ight (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private extension AppDockViewController {
    func selectCurrentAppIfExist(animation: Bool = true) {
        guard let currentApp = AppCenter.default.current, let indexOfCurrentApp = appDockItems.index(where: { $0.app == currentApp }), indexOfCurrentApp != NSNotFound else { return }
        appDockView?.selectItem(at: IndexPath(item: indexOfCurrentApp, section: 0), animated: animation)
    }
}

extension AppCenter{
    @discardableResult
    func openCurrentApp(options: AppLaunchOption?=nil, animation:Bool=false) -> Bool{
        return self.openApp(identifier: AppCenter.default.current?.info.identifier ?? "", options: options, animation: animation)
    }

    @discardableResult
    func openApp(identifier:String, options: AppLaunchOption?=nil, animation:Bool=false) -> Bool{
        if identifier.trimmed.nilEmpty != nil
        , let matchedApp = AppCenter.default.apps().first(where:{ $0.info.identifier==identifier }){
            return self.selectApp(matchedApp, options:options, animation: animation)
        }
        return false
    }

    @discardableResult
    private func selectApp(_ app:App.Type, options: AppLaunchOption?=nil, animation:Bool=false) -> Bool{
        guard let rootVc = UIApplication.shared.keyWindow?.rootViewController as? AppDockNavigationController
        , let appDockVc = rootVc.visibleViewController as? AppDockViewController else {
            return false
        }

        if let options = options{
            self.setCurrent(current: app, with: options)
        }else{
            self.current = app
        }

        DispatchQueue.mainAsyncIfNot {
            appDockVc.selectCurrentAppIfExist(animation: animation)
        }
        return true
    }
}
