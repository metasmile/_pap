//
// Created by BLACKGENE on 19/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public func isEqualAny<T: Equatable>(type: T.Type, value1: Any, value2: Any) -> Bool {
    guard let a = value1 as? T, let b = value2 as? T else {
        return false
    }
    return a == b
}