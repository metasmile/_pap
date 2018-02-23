//
// Created by BLACKGENE on 23/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol StateValueSetable {
    var hasChanges: Bool { get }
    func merge(with concatable: Self)
    func reset() -> Bool
}

public class StateValueSet<T>: MutableItemList<T>, StateValueSetable, TaskConfigable {
    public var hasChanges: Bool {
        return !self.isEmpty
    }

    public func merge(with concatable: StateValueSet<T>) {
        self.append(contentsOf: concatable)
    }

    @discardableResult
    public func reset() -> Bool {
        if self.hasChanges{
            self.removeAll()
            return true
        }
        return false
    }
}
