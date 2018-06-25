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

    //bin search
    func insertionIndexOf(_ element: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], element) {
                lo = mid + 1
            } else if isOrderedBefore(element, self[mid]) {
                hi = mid - 1
            } else {
                return mid
            }
        }
        return lo
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
