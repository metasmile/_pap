//
// Created by BLACKGENE on 09.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol _Processor{
    associatedtype InputType
    associatedtype OutputType

    init()
}

protocol Processor: _Processor {
    func process(input:InputType) -> OutputType?
}

protocol AsyncProcessor: _Processor {
    func process(input:InputType, _ asyncSignal: AsyncWaitSignalable) -> OutputType?
}