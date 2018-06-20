//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

extension VisionText{
    func parse<ParserType:VisionTextParser>(parser:ParserType) -> ParserType.OutputType?{
        return parser.parse(input: self)
    }
}

protocol VisionTextParser: Parser where Self.InputType:VisionText {
    func parse(input:VisionText) -> OutputType?
}

open class VisionTextStringParser: VisionTextParser, StringParser {
    static let shared = VisionTextStringParser()

    func parse(input: VisionText) -> String? {
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

protocol _VisionTextStringElementsParser: VisionTextParser where Self.OutputType==[String]{}
open class VisionTextStringElementsParser: _VisionTextStringElementsParser {
    static let shared = VisionTextTextBlockParser()

    func parse(input: VisionText) -> [String]? {
        return VisionTextTextBlockParser.shared.parse(input: input)?.compactMap { strings -> String? in
            return strings.joined()
        }
    }
}

open class VisionTextTextBlockParser: VisionTextParser, TextBlockParser {
    static let shared = VisionTextTextBlockParser()

    func parse(input: VisionText) -> [[String]]? {

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