//
// Created by BLACKGENE on 25/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element: Hashable { // not ordered set 
    var setable: Array {
        return Array(Set<Element>(self))
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
