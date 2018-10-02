//
//  VisionBarcodeDetector.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 10. 1..
//  Copyright © 2018년 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

class VisionBarcodeText: NSObject, VisionText {
    var frame: CGRect
    var text: String
    var cornerPoints: [NSValue]
    var visionBarcode: VisionBarcode
    
    init(visionBarcode: VisionBarcode) {
        self.visionBarcode = visionBarcode
        
        self.frame = visionBarcode.frame
        self.text = visionBarcode.rawValue ?? ""
        self.cornerPoints = visionBarcode.cornerPoints ?? []
    }
}

extension VisionBarcodeDetector{
    
    func detect(with image: UIImage, _ async: AsyncWaitSignalable) -> [VisionText]? {
        let visionImage = VisionImage(image: image)
        var result:[VisionText]?
        
        async.begin()
        self.detect(in: visionImage) { (features, error) in
            if let error = error {
                print("Received error: \(error)")
            }
            result = features?.map { VisionBarcodeText(visionBarcode: $0) }
            async.end()
        }
        async.waitUntilEnd()
        return result
    }
}
