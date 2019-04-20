//
// Created by BLACKGENE on 19.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//
import Foundation

public protocol RecordableApp: Recordable & RecordableDataSource {}

public protocol Recordable {
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    mutating func undo()
    mutating func redo()
}

public protocol RecordableDataSource: NSObjectProtocol {
    associatedtype Item
    var recordStack: [Item] { get set }
    var recordIndex: Int { get set }
    func register(_ item: Item)
    func didChangeRecordIndex(for item: Item?)
}

extension RecordableDataSource where Item: Equatable {
    public func register(_ item: Item) {
        guard recordStack[safe: recordIndex] != item else { return }
        if !recordStack.isEmpty {
            recordStack = Array<Item>(recordStack[0...max(0, recordIndex)])
        }
        recordIndex = recordStack.count
        recordStack.append(item)
    }
}

extension Recordable where Self: RecordableDataSource {
    public var canUndo: Bool { return recordIndex > 0 }
    public var canRedo: Bool { return recordIndex + 1 < recordStack.count }

    func getRecord(at index: Int) -> Item? {
        return recordStack[safe: index]
    }

    public mutating func undo() {
        guard canUndo else { return }
        recordIndex -= 1
        didChangeRecordIndex(for:getRecord(at: recordIndex))
    }

    public mutating func redo() {
        guard canRedo else { return }
        recordIndex += 1
        didChangeRecordIndex(for:getRecord(at: recordIndex))
    }
}
