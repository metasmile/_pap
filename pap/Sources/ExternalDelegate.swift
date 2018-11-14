//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

/* INFO:

- Protocol Naming: "${Class/StructName(normally e.g. "AppDelegate" in "AppDelegate.swift")}ExternalDelegate"
- External swift file naming:  ${SchemeName}.ExternalDelegate.swift

- Globally used in child apps of 'pap'
- Only DI style pattern. AVOID file by file "targets" configuration via "project.pbxproj"
  if developer do remove just only related swift file on sub app project, there are no effect with base project.
*/

public protocol AppDelegateExternalDelegate {
    func willFinishLaunching()
    func didFinishLaunching()
}

protocol AppCenterExternalDelegate {
    static var defaultConfig:AppManagerConfig{get}
}

protocol AppDockViewExternalDelegate{
    static var minimumNumberOfVisibleApps:Int{get}
}

protocol InfoStringsExternalDelegate{
    static var defaultTitle:String{get}
    static var defaultTagline:String{get}
}

extension InfoStringsExternalDelegate{
    static var nameTitle:String{
        return "\(InfoStrings.name) - \(defaultTitle)"
    }

    static var nameTitleTagLine:String{
        return "\(nameTitle): \(defaultTagline)"
    }
}

protocol AppColorDefaultThemeExternalDelegate {
    static var theme: AppColorTheme{get}
}

protocol AppColorThemeExternalDelegate {
    var textColor: UIColor{get}
    var textLightColor: UIColor{get}
    var textGrayColor: UIColor {get}
    var barStyle: UIBarStyle{get}
    var objectBackgroundColor: UIColor{get}
    var backgroundColor: UIColor{get}
    var barTintColor: UIColor? {get}
    var lineSeparatorColor: UIColor {get}
    var tintColor: UIColor{get}
    var isBarTranslucent: Bool{get}
}

protocol AppColorThemeDefaultExternalDelegate:AppColorThemeExternalDelegate {}

protocol AppColorDarkThemeExternalDelegate:AppColorThemeExternalDelegate {}