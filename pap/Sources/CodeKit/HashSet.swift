//
// Created by BLACKGENE on 8/17/18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

typealias HashSet<T> = Set<HashElement<T>>

struct HashElement<T> : Hashable {
    let type: T

    init(_ type: T) {
        self.type = type
    }

    var hashValue: Int {
        return (String(describing: self)+String(describing: type)).hashValue
    }

    static func == (lhs: HashElement, rhs: HashElement) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Array{
    var hashSet:HashSet<Element>{
        return Set(map{ HashElement($0) })
    }
}