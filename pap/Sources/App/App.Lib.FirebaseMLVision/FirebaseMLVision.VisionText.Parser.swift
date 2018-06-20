//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

protocol _VisionTextParser: Parser where Self.InputType:VisionText {}
protocol _VisionTextStringParser: StringParser, _VisionTextParser {}

open class VisionTextStringParser: _VisionTextStringParser {
    static let `default` = VisionTextStringParser()
}

extension VisionText{
    func parseAsString(parser:VisionTextStringParser?=nil) -> String?{
        return (parser ?? VisionTextStringParser.default).parse(input: self)
    }
}

extension _VisionTextStringParser {
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

