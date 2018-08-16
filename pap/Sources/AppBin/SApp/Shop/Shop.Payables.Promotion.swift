//
// Created by BLACKGENE on 8/9/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import DefaultsKit

struct PayOfInitialTutorial:Payable{
    //Actually will not be used.
    private(set) static var label: String = "Welcome Free Use Pass"

    func pay(_ asyncSignal: AsyncWaitSignalable) -> Bool {
        return Defaults.shared.shortVersionDescription == .first
    }
}