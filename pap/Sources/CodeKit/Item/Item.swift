//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public class Item<BindableType>: BindableObject<BindableType>{}
public class AnyItem: Item<Any>{}

public class ItemList<Element>: ItemObject{
    fileprivate var items = [Element]()

    public convenience init(items:[Element]){
        self.init()
        self.items = items
    }

    public var count: Int {
        return items.count
    }

    public var isEmpty: Bool {
        return items.isEmpty
    }

    public final func iterator() -> IndexingIterator<[Element]>{
        return items.makeIterator()
    }

    public func index(where predicate: (Element) throws -> Bool) -> Int?{
        do {
            return try items.index(where: predicate)
        } catch _ {
            return nil
        }
    }
}


public protocol _MutableItemList{
    associatedtype T
    func append(_ item: T)

    func append(contentsOf: Self)

    func remove(at index:Int) -> T?

    func remove(where predicate: (T) throws -> Bool) -> T?

    func removeAll()
}

public class MutableItemList<Element>: ItemList<Element>, _MutableItemList{

    public func append(_ item: Element) {
        items.append(item)
    }

    public func append(contentsOf: MutableItemList) { //Self with Protocol
        items.append(contentsOf: contentsOf.items)
    }

    public func remove(at index:Int) -> Element? {
        return items.remove(at: index)
    }

    public func remove(where predicate: (Element) throws -> Bool) -> Element? {
        guard let itemIndex = self.index(where:predicate) else {
            return nil
        }
        return remove(at:itemIndex)
    }

    public func removeAll(){
        items.removeAll()
    }
}

public class ItemQueue<Element>: MutableItemList<Element>{

    public func enqueued(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        return try items.contains(where: predicate)
    }

    public func peek(reverse:Bool=false) -> Element? {
        return isEmpty ? nil : (reverse ? items.last : items.first)
    }

    public func enqueue(_ item:Element, reverse:Bool=false) {
        reverse ? items.insert(item, at: 0) : items.append(item)
    }

    public func enqueue(contentOf:[Element], reverse:Bool=false) {
        reverse ? items.insert(contentsOf: contentOf, at: 0) : items.append(contentsOf: contentOf)
    }

    @discardableResult
    public func dequeue(reverse:Bool=false) -> Element? {
        return isEmpty ? nil : (reverse ? items.removeLast() : items.removeFirst())
    }

    @discardableResult
    public func dequeueAll(reverse:Bool=false) -> [Element]? {
        if isEmpty {
            return nil
        }
        var remainingItems = [Element]()
        while let item = dequeue(){
            remainingItems.append(item)
        }
        return remainingItems
    }
}

public class IndexItem: Item<UInt>{
    override func bind(_ bindingObject: UInt?) -> UInt? {
        self.index = bindingObject!
        return bindingObject
    }
}

public class ParameterItem<ValueType>: Item<ValueType>{
    public typealias conformsValueType = ValueType

    public var label:String?
    public var key:String?
    public var value:conformsValueType?
    public var defaultValue:conformsValueType?{
        get{
            return self.bindedObject
        }
    }

    override func bind(_ bindingObject: conformsValueType?) -> conformsValueType? {
        self.value = bindingObject
        return bindingObject
    }
}

