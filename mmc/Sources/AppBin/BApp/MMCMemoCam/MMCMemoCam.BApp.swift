//
//  MMCMemoCam.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 7. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

class MMCMemoCamApp: MemoCamApp, SubApp{
    public static let subInfo:AppInfo = AppInfo(
            identifier: "com.stells.pap.memocam"
            , version: "1.0"
            , phase: .release
            , appType: MMCMemoCamApp.self
            , displayName: "Camera".localized.localizedCapitalized, description:nil, keywords:nil
            , icon: AppIcon(source: "camera", style: .themeColor)
            , themeColor: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )
}
