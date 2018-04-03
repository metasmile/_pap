//
//  CodeKit.UIImage.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 3..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

public extension UIImage {
    func applyFilter(ciFilter: CIFilter?) -> UIImage {
        guard let filter = ciFilter else { return self }
        filter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage, let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else { return self }
        return UIImage(cgImage: cgImage)
    }
}
