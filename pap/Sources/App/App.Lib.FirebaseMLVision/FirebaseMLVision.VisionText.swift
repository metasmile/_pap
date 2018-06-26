//
// Created by BLACKGENE on 22.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

extension Array where Element:VisionText {
    func parse<ParserType: VisionTextParser>(parser: ParserType, _ async: AsyncManualSignalable) -> [ParserType.OutputType]? {
        return self.compactMap { visionText -> ParserType.OutputType? in
            return parser.parse(input: visionText)
        }
    }

    func parse<ParserType:VisionTextParser>(type: ParserType.Type, _ async: AsyncManualSignalable) -> [ParserType.OutputType]? {
        return self.parse(parser: type.shared, async)
    }
}
extension VisionText{
    func parse<ParserType:VisionTextParser>(parser:ParserType) -> ParserType.OutputType?{
        return parser.parse(input: self)
    }
}
