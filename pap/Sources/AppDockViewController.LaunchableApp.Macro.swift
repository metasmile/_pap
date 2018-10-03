//
// Created by BLACKGENE on 10/3/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

// Common Macros
extension AppCenter{

    @discardableResult
    func openCamera(captureOption:CameraApp.CaptureOption?=nil, returningIdentifier:String?=AppCenter.default.current?.info.identifier) -> Bool{
        var option = AppLaunchOptions()

        var options = [AppLaunchOptionsKey:Any]()
        options[.CameraAppCaptureOption] = captureOption

        option.options = options
        option.identifierToReturn = returningIdentifier

        let opened = openApp(identifier:CameraApp.info.identifier, options:option)

        papLog.app.userCalledCameraInApp()

        return opened
    }
}