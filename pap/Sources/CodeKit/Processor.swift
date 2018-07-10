//
// Created by BLACKGENE on 09.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol Processor {
    associatedtype InputType
    associatedtype OutputType

    func process(input:InputType) -> OutputType?

    init()
}

protocol AsyncProcessor: Processor {
    func process(input:InputType, _ asyncSignal: AsyncWaitSignalable?) -> OutputType?
}

extension AsyncProcessor{
    func process(input: InputType) -> OutputType? {
        return self.process(input: input, nil)
    }
}