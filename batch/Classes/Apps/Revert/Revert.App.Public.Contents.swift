//
// Created by BLACKGENE on 23/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public extension BatchAppPHAssetState {
    public var hasChangesToRevert: Bool {
        return false
    }
}

public extension StateValueSet where T: BatchAppPHAssetState {
    public var hasChangesToRevert: Bool {
        return false
    }
}
