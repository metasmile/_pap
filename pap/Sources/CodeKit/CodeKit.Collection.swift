//
// Created by BLACKGENE on 20/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

extension Collection {
    func dictionary<K:Hashable, V>(transform:(_ element: Iterator.Element) -> (key:K, value:V)) -> [K : V] {
        return self.reduce(into: [K : V]()) { (dictionary, value) in
            let t = transform(value)
            dictionary[t.key] = t.value
        }
    }
}