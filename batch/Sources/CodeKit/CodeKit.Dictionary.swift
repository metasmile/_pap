//
// Created by BLACKGENE on 24/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension Dictionary{
    @available(swift 4.0)
    public var keysArray: [Key] {
        return Array(self.keys)
    }

    @available(swift 4.0)
    public var valuesArray: [Value]{
        return Array(self.values)
    }
}