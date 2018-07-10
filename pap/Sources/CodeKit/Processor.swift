//
// Created by BLACKGENE on 09.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol Processor {
    associatedtype InputType
    associatedtype OutputType

    func parse(input:InputType) -> OutputType?

    init()
}

protocol AsyncProcessor: Processor {
    func parse(input:InputType, asyncSingal:AsyncManualSignalable?) -> OutputType?
}

extension AsyncProcessor{
    func parse(input: InputType) -> OutputType? {
        return self.parse(input: input, asyncSingal: nil)
    }
}