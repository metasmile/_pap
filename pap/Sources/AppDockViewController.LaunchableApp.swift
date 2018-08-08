//
// Created by BLACKGENE on ?14.07.18.
// Copyr?ight (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private extension AppDockViewController {
    func selectCurrentAppIfExist(animation: Bool = true) {
        guard let currentApp = AppCenter.default.current
        , let indexOfCurrentApp = appDockItems.index(where: { $0.app == currentApp }), indexOfCurrentApp != NSNotFound else {
            return
        }

        appDockView?.selectItem(at: IndexPath(item: indexOfCurrentApp, section: 0), animated: animation)
    }
}

extension AppCenter{
    @discardableResult
    func openCurrentApp(options: AppLaunchOption?=nil, animation:Bool=false) -> Bool{
        return self.openApp(identifier: AppCenter.default.current?.info.identifier ?? "", options: options, animation: animation)
    }

    /* INFO:
    When set "identifier" in App internal code, use string literal instead of reference.
    e.g. - AppCenter.default.openApp(identifier:"com.stells.pap.camera")
    */
    @discardableResult
    func openApp(identifier:String, options: AppLaunchOption?=nil, animation:Bool=false) -> Bool{
        if identifier.trimmed.nilEmpty != nil
        , let matchedApp = AppCenter.default.apps().first(where:{ $0.info.identifier==identifier }){
            var mutableOption = options

            var defaultLaunchingOptions = mutableOption?.options ?? [AppLaunchOptionsKey:Any]()

            //set basically current app to source app if it didn't defined.
            if defaultLaunchingOptions[.SourceAppType] == nil{
                defaultLaunchingOptions[.SourceAppType] = self.current
                mutableOption?.options = defaultLaunchingOptions
            }

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

        let willChange = self.current != app

        if let options = options{
            self.setCurrent(current: app, with: options)
        }else{
            self.current = app
        }

        DispatchQueue.mainAsyncIfNot {
            appDockVc.selectCurrentAppIfExist(animation: animation)
            if willChange{
                appDockVc.appDidChange()
            }
        }
        return true
    }
}
