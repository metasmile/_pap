//
// Created by BLACKGENE on 8/10/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol ManagerConfigurableApp :App {
    static func didConfigure(with manager:AppManager)
}