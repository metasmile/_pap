//
//  VisionBarcodeDetector.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 10. 1..
//  Copyright © 2018년 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision

class VisionBarcodeText: VisionTextBlock {
    var visionBarcode: VisionBarcode
    
    init(visionBarcode: VisionBarcode) {
        self.visionBarcode = visionBarcode
    }
    
    override var cornerPoints: [NSValue]? {
        return visionBarcode.cornerPoints
    }
    
    override var frame: CGRect {
        return visionBarcode.frame
    }
    
    override var text: String {
        return visionBarcode.rawValue ?? ""
    }
}

extension VisionBarcodeDetector{
    
    func detect(with image: UIImage, _ async: AsyncWaitSignalable) -> [VisionBarcodeText]? {
        let visionImage = VisionImage(image: image)
        var result:[VisionBarcodeText]?
        
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
