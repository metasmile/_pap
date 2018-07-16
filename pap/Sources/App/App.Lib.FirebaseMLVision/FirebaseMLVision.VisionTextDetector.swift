//
// Created by BLACKGENE on 2?0.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

extension VisionTextDetector{

    func detect(with image: UIImage, _ async: AsyncWaitSignalable) -> [VisionText]? {
        let visionImage = VisionImage(image: image)
        var result:[VisionText]?

        async.begin()
        self.detect(in: visionImage) { features, error in
            if let error = error {
                print("Received error: \(error)")
            }
            result = features
            async.end()
        }
        async.waitUntilEnd()
        return result
    }
}