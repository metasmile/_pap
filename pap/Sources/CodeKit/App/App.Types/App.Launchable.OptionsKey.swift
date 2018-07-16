//
// Created by BLACKGENE on 14.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

/*
    AVFoundation, PhotosKit
*/
extension AppLaunchOptionsKey {
    //value type: PHAsset
    static let PHAsset = AppLaunchOptionsKey(rawValue:0)

    //value type: URL
    static let PhotoURL = AppLaunchOptionsKey(rawValue:1)

    //value type: URL
    static let PairedVideoURL = AppLaunchOptionsKey(rawValue:2)
}