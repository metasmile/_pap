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

    didOpen(Bool) - true: "changed", false: "did not changed"
    */
    @discardableResult
    func openApp(identifier:String, options: AppLaunchOptions?=nil, animation:Bool=false, didOpen:((Bool) -> ())?=nil) -> Bool{
        if identifier.trimmed.nilEmpty != nil
        , let matchedApp = AppCenter.default.apps().first(where:{ $0.info.identifier==identifier }){

            var passingOption:AppLaunchOptions? = options

            //set basically current app to source app if it didn't defined.
            if options?.options?[.SourceAppType] == nil{
                var mutableOption = options ?? AppLaunchOptions()
                var defaultLaunchingOptions = mutableOption.options ?? [AppLaunchOptionsKey:Any]()
                defaultLaunchingOptions[.SourceAppType] = self.current
                mutableOption.options = defaultLaunchingOptions
                passingOption = mutableOption
            }

            return self.selectApp(matchedApp, options:passingOption, animation: animation, didOpen:didOpen)
        }
        return false
    }

    @discardableResult
    private func selectApp(_ app:App.Type, options: AppLaunchOptions?=nil, animation:Bool=false, didOpen:((Bool) -> ())?=nil) -> Bool{
        guard let rootVc = UIApplication.shared.keyWindow?.rootViewController as? AppDockNavigationController else {
            return false
        }

        var _appDockVc:AppDockViewController?
        if let vc = rootVc.visibleViewController as? AppDockViewController{
            _appDockVc = vc
        }else if let vc = rootVc.viewControllers.first(where:{ $0 is AppDockViewController }) as? AppDockViewController {
            // for a case what visibleViewController is not, and other vc was stacked(or pending animations to dismiss) for a moment, but openApp immediately called before.
            _appDockVc = vc
        }
        guard let appDockVc = _appDockVc else {
            assert(false, "Not found AppDockViewController while try to open app.")
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

            didOpen?(willChange)
        }
        return true
    }
}
