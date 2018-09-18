//
// Created by BLACKGENE on 2018-09-18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

struct PermanentVIPSecretCodeProgram:SecretCodeProgram{
    static var title: String {
        return "VIP License Program".localized
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