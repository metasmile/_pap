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
        var results:String = ""

        if let block = input as? VisionTextBlock {
            //block
            var wordsInLine = ""
            for line in block.lines {
                //line
                for element in line.elements where element.text.count > 0 {
                    //word
                    wordsInLine += element.text + " "
                }

                if wordsInLine.count > 0{
                    wordsInLine += "\n"
                }
            }
            if wordsInLine.count > 0{
                results += wordsInLine + "\n"
            }
        }

        return results
    }
}

open class VisionTextTextBlockParser: VisionTextParser, TextBlockParser {
    static let shared = VisionTextTextBlockParser()

    func parse(input: VisionText) -> [[String]]? {
        var lines = [[String]]()

        if let block = input as? VisionTextBlock {
            //block
            var linesInBlock = [[String]]()

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

            if linesInBlock.count > 0{
                lines += linesInBlock
            }
        }

        return lines
    }
}