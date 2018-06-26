//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

protocol VisionTextParser: Parser where Self.InputType==VisionText {
    static var shared:Self {get}
    func parse(input:VisionText) -> OutputType?
}

struct VisionTextStringParser: VisionTextParser {
    typealias OutputType = String

    static let shared = VisionTextStringParser()

    func parse(input: VisionText) -> OutputType? {
        guard let lines = VisionTextTextBlockParser.shared.parse(input: input) else {
            return nil
        }

        var results:String = ""

        for line in lines{
            var wordsInLine = ""

            for word in line {
                wordsInLine += word + " "
            }

            if wordsInLine.count > 0{
                results += "\n" + wordsInLine
            }
        }

        if results.count > 0{
            return results + "\n"
        }

        return nil
    }
}

public struct VisionTextStringElementsParser: VisionTextParser {
    typealias OutputType = [String]

    static let shared = VisionTextStringElementsParser()

    func parse(input: VisionText) -> OutputType? {
        return VisionTextTextBlockParser.shared.parse(input: input)?.compactMap { strings -> String? in
            return strings.joined()
        }
    }
}

public struct VisionTextTextBlockParser: VisionTextParser {
    typealias OutputType = [[String]]

    static let shared = VisionTextTextBlockParser()

    func parse(input: VisionText) -> OutputType? {

        if let block = input as? VisionTextBlock {
            var linesInBlock = [[String]]()

            //block
            for line in block.lines {
                //line
                var wordsInLine = [String]()
                for element in line.elements where element.text.count > 0 {
                    //word
                    wordsInLine.append(element.text)
                }

                if wordsInLine.count > 0{
                    linesInBlock.append(wordsInLine)
                }
            }

            return linesInBlock
        }

        return nil
    }
}