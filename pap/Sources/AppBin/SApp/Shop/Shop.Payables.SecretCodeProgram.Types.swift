//
// Created by BLACKGENE on 2018-09-18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

struct PermanentVIPSecretCodeProgram:SecretCodeProgram{
    static var title: String {
        return "VIP Membership Program".localized
    }
    static var grantedMessage: String {
        return "Welcome to our VIP license program.".localized
    }
    static var defaultOwnerName: String{
        return "VIP \(UUID.fixedShortUUIDString)"
    }

    static var program: String? {
        return nil
    }

    static var isEnable: Bool = false

    static var currentAppIDStack:[String]?

    static var passCodeAppIDStack:[String] {
        return [
            PDFactoryApp.info.identifier,
            ConverterApp.info.identifier,
            TransformApp.info.identifier,
            FiltersApp.info.identifier
        ]
    }
}

struct SpecialGuestSecretCodeProgram:SecretCodeProgram{
    static var shouldExpire: Bool{
        return true
    }

    static var title: String {
        return "Special Guest License Program".localized
    }
    static var grantedMessage: String {
        return "Welcome to our special guest license program!".localized
    }

    static var program: String? {
        return "special_guest"
    }
    static var defaultOwnerName: String {
        return "\("Special Guest".localized) \(UUID.fixedShortUUIDString)"
    }

    static var isEnable: Bool = false

    static var currentAppIDStack:[String]?

    static var passCodeAppIDStack:[String] {
        return [
            ConverterApp.info.identifier,
            PDFactoryApp.info.identifier,
            FiltersApp.info.identifier,
            TransformApp.info.identifier
        ]
    }
}

struct PromotionSecretCodeProgram:SecretCodeProgram{
    static var shouldExpire: Bool{
        return true
    }

    static var title: String {
        return "Promotion License Program".localized
    }
    static var grantedMessage: String {
        return "Welcome to our promotion license program!".localized
    }

    static var program: String? {
        return "promotion"
    }
    static var defaultOwnerName: String {
        return "\("Promotion User".localized) \(UUID.fixedShortUUIDString)"
    }

    static var isEnable: Bool = false

    static var currentAppIDStack:[String]?

    static var passCodeAppIDStack:[String] {
        return [
            FiltersApp.info.identifier,
            TransformApp.info.identifier,
            ConverterApp.info.identifier,
            PDFactoryApp.info.identifier
        ]
    }
}