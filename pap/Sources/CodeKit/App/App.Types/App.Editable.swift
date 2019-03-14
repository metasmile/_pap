//
// Created by BLACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

public protocol EditableApp: App {
    var defaultEditStateValue: ImageEditStateValue? { get }
    func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?)
    func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?)
}

extension EditableApp {
    public var defaultEditStateValue: ImageEditStateValue? { return nil }
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {}
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {}
}

public protocol UndoableApp: Undoable & UndoableDataSource {}

public protocol Undoable {
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    mutating func undo()
    mutating func redo()
}

public protocol UndoableDataSource: NSObjectProtocol {
    associatedtype UndoItem
    var undoStack: [UndoItem] { get set }
    var undoItemIndex: Int { get set }
    func registerUndo(_ item: UndoItem)
    func undoItemIndexDidChange(_ item: UndoItem?)
}

extension UndoableDataSource where UndoItem: Equatable {
    public func registerUndo(_ item: UndoItem) {
        print(#function, self.undoStack[safe: self.undoItemIndex], item, self.undoStack[safe: self.undoItemIndex] == item)
        guard self.undoStack[safe: self.undoItemIndex] != item else { return }
        if !self.undoStack.isEmpty {
            self.undoStack = Array<UndoItem>(self.undoStack[0...max(0, self.undoItemIndex)])
        }
        self.undoItemIndex = self.undoStack.count
        self.undoStack.append(item)
    }
}

extension Undoable where Self: UndoableDataSource {
    public var canUndo: Bool { return undoItemIndex > 0 }
    public var canRedo: Bool { return undoItemIndex + 1 < undoStack.count }
    
    func undoItem(at index: Int) -> UndoItem? {
        return undoStack[safe: index]
    }
    
    public mutating func undo() {
        guard self.canUndo else { return }
        self.undoItemIndex -= 1
        self.undoItemIndexDidChange(undoItem(at: self.undoItemIndex))
    }
    
    public mutating func redo() {
        guard self.canRedo else { return }
        self.undoItemIndex += 1
        self.undoItemIndexDidChange(undoItem(at: self.undoItemIndex))
    }
}
