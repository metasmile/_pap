//
// Created by BLACKGENE on 20.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

extension VisionCloudTextDetector{

    func detect(with image: UIImage, _ async: AsyncWaitSignalable) -> VisionCloudText? {
        let visionImage = VisionImage(image: image)

        var result:VisionCloudText?

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

    func processToString(from text: VisionCloudText?, _ async: AsyncWaitSignalable?=nil) {
        guard let features = text, let pages = features.pages else {
            return
        }

        var testResults:String = ""

        for page in pages {
            for block in page.blocks ?? []  {
                for paragraph in block.paragraphs ?? [] {
                    for word in paragraph.words ?? [] {
                        if let symbols = word.symbols{
                            for symbol in symbols {
                                testResults += symbol.text ?? "" + "|"
                            }
                        }
                    }
                }
            }
        }
        async?.begin()
        DispatchQueue.main.async {
            UIAlertController.alert(testResults != "" ? testResults : "Not found any text", completion:{ _ in
                async?.end()
            })
        }
        async?.waitUntilEnd()
    }
}