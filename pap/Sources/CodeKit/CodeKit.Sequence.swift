//
// Created by BLACKGENE on 31/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

#if !swift(>=4.1)
extension Sequence {
    func compactMap<T>(_ transform: (Self.Element) throws -> T?) rethrows -> [T] {
        return try flatMap(transform)
    }
}
#endif
