//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public class Item<BindableType>: BindableObject<BindableType>{}
public class AnyItem: Item<Any>{}

public class ItemQueue<Element>: ItemObject{
    private var items = [Element]()

    public var count: Int {
        return items.count
    }

    public var isEmpty: Bool {
        return items.isEmpty
    }

    public func peek(reverse:Bool=false) -> Element? {
        return isEmpty ? nil : (reverse ? items.last : items.first)
    }

    public func enqueue(_ item:Element, reverse:Bool=false) {
        reverse ? items.insert(item, at: 0) : items.append(item)
    }

    public func dequeue(reverse:Bool=false) -> Element? {
        return isEmpty ? nil : (reverse ? items.removeLast() : items.removeFirst())
    }

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

    public final func iterator() -> IndexingIterator<[Element]>{
        return items.makeIterator()
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

    public func index(where predicate: (Element) throws -> Bool) -> Int?{
        do {
            return try items.index(where: predicate)
        } catch _ {
            return nil
        }
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


public class ImageParameterItem: ParameterItem<ImageSourceable> {
    public var image:ImageSourceable?{
        get{
            return self.value
        }
    }
}
