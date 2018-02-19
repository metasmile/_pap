//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public protocol EditableValue {

}

public protocol EditableTransformValue: EditableValue {
    var asTransform: CGAffineTransform { get }
    var asTransform3d: CATransform3D { get }
}

extension TransformItem{
    public var asTransform: CGAffineTransform {
        return self.transform
    }
    public var asTransform3d: CATransform3D {
        return self.transform3d
    }
}

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