//
//  CodeKit.UIImage.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 3..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

public extension UIImage {
    private static let sharedCIContextForFilter = CIContext()
    
    func applyFilter(ciFilter: CIFilter?) -> UIImage {
        guard let filter = ciFilter, filter.inputKeys.contains(kCIInputImageKey) else { return self }
        filter.setValue(self.asCIImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage, let cgImage = UIImage.sharedCIContextForFilter.createCGImage(outputImage, from: outputImage.extent) else { return self }
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


    //https://github.com/SwifterSwift/SwifterSwift/blob/master/Sources/Extensions/UIKit/UIImageExtensions.swift
    public func rounded(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    var hasAlpha: Bool {
        let alpha: CGImageAlphaInfo = self.cgImage!.alphaInfo
        switch alpha {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }
    
    //https://nshipster.com/image-resizing/
    func resize(in size: CGSize) -> UIImage? {
        guard size != self.size else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}

public extension UIImage {
    //https://robots.thoughtbot.com/designing-for-ios-blending-modes
    func tintColor(_ color: UIColor, blendMode: CGBlendMode = .normal) -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        let drawRect = CGRect(origin: .zero, size: size)
        return UIGraphicsImageRenderer(size: size).imageWithCurrentContext { (ctx) in
            ctx.scaleBy(x: 1, y: -1)
            ctx.translateBy(x: 0, y: -size.height)
            
            ctx.setBlendMode(blendMode)
            ctx.clip(to: drawRect, mask: cgImage)
            
            ctx.setFillColor(color.cgColor)
            ctx.fill(drawRect)
        }?.withRenderingMode(.alwaysOriginal) ?? self
    }
}
