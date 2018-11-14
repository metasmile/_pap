//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

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
    static var externalConfig:AppManagerConfig{get}
}