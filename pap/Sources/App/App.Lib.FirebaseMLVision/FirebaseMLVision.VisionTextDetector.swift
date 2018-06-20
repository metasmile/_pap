//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

extension VisionTextDetector{

    func detect(with image: UIImage, _ async: AsyncManualSignalable) -> [VisionText]? {
        let visionImage = VisionImage(image: image)
        let textDetector = self

        var result:[VisionText]?

        async.begin()
        textDetector.detect(in: visionImage) { features, error in
            if let error = error {
                print("Received error: \(error)")
            }
            result = features
            async.end()
        }
        async.waitUntilEnd()
        return result
    }

    func detect<ParserType:VisionTextParser>(with image: UIImage, parser: ParserType, _ async: AsyncManualSignalable) -> [ParserType.OutputType]? {
        if let detectResults:[VisionText] = self.detect(with: image, async) {
            return detectResults.compactMap { visionText -> ParserType.OutputType? in
                return parser.parse(input: visionText)
            }
        }
        return nil
    }

    func detect<ParserType:VisionTextStringParser>(with image: UIImage, parser: ParserType?=nil, _ async: AsyncManualSignalable) -> [ParserType.OutputType]? {
        return self.detect(with: image, parser: parser ?? ParserType.shared, async)
    }

    func detect<ParserType:VisionTextTextBlockParser>(with image: UIImage, parser: ParserType?=nil, _ async: AsyncManualSignalable) -> [ParserType.OutputType]? {
        return self.detect(with: image, parser: parser ?? ParserType.shared, async)
    }
}