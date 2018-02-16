//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

extension TransformAppAsset: TaskParamable{}

public protocol Editable{
    var hasChanges: Bool { get }
    func merge(with concatable: Self)
    func reset() -> Bool
}

public class EditableItem<T>: MutableItemList<T>, Editable, TaskConfigable {

    public var hasChanges: Bool {
        return !self.isEmpty
    }

    public func merge(with concatable: EditableItem<T>) {
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

