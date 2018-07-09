//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision


extension VisionCloudText{
    func parseToString() -> String?{
        return VisionCloudTextParser.default.parse(input: self)
    }
}

struct VisionCloudTextParser: Processor {
    typealias InputType = VisionCloudText
    typealias OutputType = String

    static let `default` = VisionCloudTextParser()

    func parse(input: VisionCloudText) -> String? {
        guard let pages = input.pages else {
            return nil
        }

        var testResults:String = ""

        for page in pages {
            for block in page.blocks ?? []  {
                for paragraph in block.paragraphs ?? [] {
                    for word in paragraph.words ?? [] {
                        if let symbols = word.symbols{
                            for symbol in symbols {
                                testResults += symbol.text ?? "" + " "
                            }
                        }
                    }
                }
            }
        }

        return testResults
    }
}
