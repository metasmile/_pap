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
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }

    static func createNumberedSequenceImages(renderBounds:CGRect, count:Int, color:UIColor) -> [UIImage]{
        var images = [UIImage]()
        for i in 0..<count {
            images.append(UIGraphicsImageRenderer(bounds: renderBounds).imageWithCurrentContext { (cgContext) in
                cgContext.setFillColor(color.cgColor)
                cgContext.fill(renderBounds)

                let attrString = NSAttributedString(string: "\(i + 1)", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
                let stringSize = attrString.size()

                attrString.draw(at: CGPoint(x: max(0, (renderBounds.width - stringSize.width) / 2), y: max(0, (renderBounds.height - stringSize.height) / 2)))
            } ?? UIImage())
        }
        return images
    }
}
