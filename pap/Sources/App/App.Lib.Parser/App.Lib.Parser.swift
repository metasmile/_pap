//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol Parser {
    associatedtype InputType
    associatedtype OutputType

    func parse(input:InputType) -> OutputType?

    init()
}

protocol MergingParser: Parser {
    func parse(input:InputType, mergingOutput:OutputType) -> OutputType?
}

protocol StringParser: Parser where Self.OutputType==String {
    func parse(input:InputType) -> OutputType?
}

// INFO line by line [["word","word","word","word"],["word","word","word","word"],["word","word","word","word"]]
protocol TextBlockParser: Parser where Self.OutputType==[[String]] {
    func parse(input:InputType) -> OutputType?
}
