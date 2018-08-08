//
// Created by BLACKGENE on 14.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

/*
    App, AppInfo
*/
extension AppLaunchOptionsKey {
    //value type: PHAsset
    static let SourceAppType = AppLaunchOptionsKey(rawValue:0)
}

/*
    AVFoundation, PhotosKit
*/
extension AppLaunchOptionsKey {
    //value type: PHAsset
    static let PHAsset = AppLaunchOptionsKey(rawValue:200)

    //value type: URL
    static let PhotoURL = AppLaunchOptionsKey(rawValue:201)

    //value type: URL
    static let PairedVideoURL = AppLaunchOptionsKey(rawValue:203)
}