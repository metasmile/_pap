//
// Created by BLACKGENE on 08/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
}