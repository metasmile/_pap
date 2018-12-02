//
// Created by BLACKGENE on 31/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension Sequence{
    #if !swift(>=4.1)
    func compactMap<T>(_ transform: (Self.Element) throws -> T?) rethrows -> [T] {
        return try flatMap(transform)
    }
    #endif

    //INFO: Difference with Set(Array) is "ordered."
    func uniq<T:Hashable>() -> [T] where Self.Iterator.Element == T {
        var buffer = [T]()
        var added = Set<T>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}

