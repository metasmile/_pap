//
// Created by BLACKGENE on 09.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

//TODO: AsyncProcessor

protocol Processor {
    associatedtype InputType
    associatedtype OutputType

    func parse(input:InputType) -> OutputType?

    init()
}