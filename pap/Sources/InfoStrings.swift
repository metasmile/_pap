//
// Created by BLACKGENE on 2018-11-14.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

struct InfoStrings {
    private static let kAppStoreID = "AppStoreID"

    static var appStoreId:String{
        return (Bundle.main.object(forInfoDictionaryKey: kAppStoreID) as? String) ?? ""
    }

    static var name:String{
        return Bundle.main.displayName ?? "PAPS"
    }

    static var title: String {
        return extDelegate?.defaultTitle ?? ""
    }

    static var tagline: String {
        return extDelegate?.defaultTagline ?? ""
    }

    static var nameTitle:String{
        return extDelegate?.nameTitle ?? ""
    }

    static var nameTitleTagLine:String{
        return extDelegate?.nameTitleTagLine ?? ""
    }

    fileprivate static var extDelegate:InfoStringsExternalDelegate.Type?{
        let anySelf:Any.Type = self
        return anySelf as? InfoStringsExternalDelegate.Type
    }
}