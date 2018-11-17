//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension PhotoEditViewController:AppDockViewControllerAppConfigWatchableDelegate {

    func registerWatchingAppConfig(){

    }

    func unregisterWatchingAppConfig(){
        AppCenter.default.unwatch(\.currentIdentifier, forIds:["editor"])
    }

}