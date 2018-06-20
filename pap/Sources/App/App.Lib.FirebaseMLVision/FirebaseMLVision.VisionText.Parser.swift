//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

extension VisionText{
    func parseToString() -> String?{
        return VisionTextParser.default.parse(input: self)
    }
}

struct VisionTextParser: Parser{
    static let `default` = VisionTextParser()

    typealias InputType = VisionText
    typealias OutputType = String

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
