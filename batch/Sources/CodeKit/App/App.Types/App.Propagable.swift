//
// Created by BLACKGENE on 02/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol PropagableApp: App {
    func propagateAppStateHasChanged()
}