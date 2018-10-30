//
// Created by BLACKGENE on 22/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public typealias SequenceOptionSet = OptionSet & Sequence

public extension OptionSet where Self.RawValue == Int, Self:Sequence {
    public func makeIterator() -> OptionSetIterator<Self> {
        return OptionSetIterator(element: self)
    }

    public var underestimatedCount: Int{
        var count = 0
        var iter = makeIterator()
        while let _ = iter.next(){
            count+=1
        }
        return count
    }
}

public struct OptionSetIterator<Element: OptionSet>: IteratorProtocol where Element.RawValue == Int {
    private let value: Element

    public init(element: Element) {
        self.value = element
    }

    private lazy var remainingBits = value.rawValue
    private var bitMask = 1

    public mutating func next() -> Element? {
        while remainingBits != 0 {
            defer { bitMask = bitMask &* 2 }
            if remainingBits & bitMask != 0 {
                remainingBits = remainingBits & ~bitMask
                return Element(rawValue: bitMask)
            }
        }
        return nil
    }
}

