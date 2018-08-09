//
// Created by BLACKGENE o??n ?14.07.18.
// Copyr?ight (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

private extension AppDockViewController {
    private var indexPathOfCurrentApp: IndexPath? {
        guard let currentApp = AppCenter.default.current else { return nil }
        for (section, group) in appDockItemGroups.enumerated() {
            if let item = group.index(where: { $0.app == currentApp }), item != NSNotFound {
                return IndexPath(item: item, section: section)
            }
        }
        return nil
    }
    
    func selectCurrentAppIfExist(animation: Bool = true) {
        guard let selectedIndexPath = indexPathOfCurrentApp else { return }
        print(selectedIndexPath, appDockItems)
        appDockView?.selectItem(at: selectedIndexPath, animated: animation)
    }
}

extension AppCenter{
    @discardableResult
    func openCurrentApp(options: AppLaunchOptions?=nil, animation:Bool=false) -> Bool{
        return self.openApp(identifier: AppCenter.default.current?.info.identifier ?? "", options: options, animation: animation)
    }

    /* INFO:
    When set "identifier" in App internal code, use string literal instead of reference.
    e.g. - AppCenter.default.openApp(identifier:"com.stells.pap.camera")
    */
    @discardableResult
    func openApp(identifier:String, options: AppLaunchOptions?=nil, animation:Bool=false) -> Bool{
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
    private func selectApp(_ app:App.Type, options: AppLaunchOptions?=nil, animation:Bool=false) -> Bool{
        guard let rootVc = UIApplication.shared.keyWindow?.rootViewController as? AppDockNavigationController
            , let appDockVc = rootVc.visibleViewController as? AppDockViewController else { //INFO: current modal or vc (for photo editor)
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
