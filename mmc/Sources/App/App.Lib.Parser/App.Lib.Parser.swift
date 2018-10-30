//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

protocol MergingParser: Processor {
    func process(input:InputType, mergingOutput:OutputType) -> OutputType?
}

protocol StringParser: Processor where Self.OutputType==String {
    func process(input:InputType) -> OutputType?
}

// INFO line by line [["word","word","word","word"],["word","word","word","word"],["word","word","word","word"]]
protocol TextBlockParser: Processor where Self.OutputType==[[String]] {
    func process(input:InputType) -> OutputType?
}
