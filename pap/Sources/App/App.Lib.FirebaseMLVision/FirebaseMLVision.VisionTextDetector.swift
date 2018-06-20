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

    func detectStrings(with image: UIImage, parser: VisionTextStringParser?=nil, _ async: AsyncManualSignalable) -> [String]? {
        if let detectResults:[VisionText] = self.detect(with: image, async) {
            return detectResults.compactMap { visionText -> String? in
                return visionText.parseAsString(parser: parser)
            }
        }
        return nil
    }
}