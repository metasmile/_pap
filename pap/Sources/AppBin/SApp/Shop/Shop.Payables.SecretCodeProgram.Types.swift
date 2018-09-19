//
// Created by BLACKGENE on 2018-09-18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

struct PermanentVIPSecretCodeProgram:SecretCodeProgram{
    static var title: String {
        return "VIP Membership Program".localized
    }
    static var grantedMessage: String {
        return "Welcome to our VIP license program.".localized
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
        return "sg"
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