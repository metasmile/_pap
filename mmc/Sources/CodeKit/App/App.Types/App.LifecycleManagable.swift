//
// Created by BLACKGENE on 05.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol LifecycleManageableApp :App {
    func willAcquire() -> Bool
    func willDiscard() -> Bool
}