//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol Parser {
    associatedtype InputType
    associatedtype OutputType

    func parse(input:InputType) -> OutputType?
}
