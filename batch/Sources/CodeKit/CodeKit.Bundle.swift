//
// Created by BLACKGENE on 08/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }

    var schemes:[String]? {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: AnyObject]] else {
            return [String]()
        }

        return urlTypes.compactMap { $0["CFBundleURLSchemes"] as? [String] }.reduce([], +).nilEmpty
    }

    var version:String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    var shortVersionString:String?{
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

