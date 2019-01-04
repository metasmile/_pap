//
//  CodeKit.UIImage.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 3..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Accelerate

public extension UIImage {
    
    func applyFilter(ciFilter: CIFilter?) -> UIImage? {
        return autoreleasepool { () -> UIImage? in
            guard let filter = ciFilter, filter.inputKeys.contains(kCIInputImageKey) else { return nil }
            filter.setValue(self.asCIImage, forKey: kCIInputImageKey)
            return filter.outputImage?.asUIImage
        }
    }

    static func createNumberedSequenceImages(renderBounds:CGRect, count:Int, color:UIColor) -> [UIImage]{
        var images = [UIImage]()
        for i in 0..<count {
            images.append(UIGraphicsImageRenderer(bounds: renderBounds).imageWithCurrentContext { (cgContext) in
                cgContext.setFillColor(color.cgColor)
                cgContext.fill(renderBounds)

                let attrString = NSAttributedString(string: "\(i + 1)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
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
    
    //INFO: Old way
    func resize(to size: CGSize) -> UIImage? {
        guard size != self.size else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }

    //INFO: Use this default
    func re(size:CGSize) -> UIImage? {
        if let resizedCgImage = self.cgImage?.re(size: size){
            return UIImage(cgImage: resizedCgImage, scale: self.scale, orientation: self.imageOrientation)
        }
        return nil
    }


    func resize(aspectFit size: CGSize) -> UIImage? {
        guard size != self.size else { return self }
        
        let resize = self.size.aspectFit(in: size)
        
        UIGraphicsBeginImageContextWithOptions(resize, false, 0)
        draw(in: CGRect(origin: .zero, size: resize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func resize(aspectFill size: CGSize) -> UIImage? {
        guard size != self.size else { return self }
        
        let resize = self.size.aspectFit(in: size)
        
        UIGraphicsBeginImageContextWithOptions(resize, false, 0)
        draw(in: CGRect(origin: .zero, size: resize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func crop(aspectFill size: CGSize) -> UIImage? {
        guard size != self.size else { return self }
        
        let resize = self.size.aspectFill(in: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(origin: CGPoint(x: min(0, (size.width - resize.width) / 2), y: min(0, (size.height - resize.height) / 2)), size: resize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }

    func crop(aspectFillInset inset: CGPoint) -> UIImage? {
        let scale = UIScreen.main.scale
        return self.crop(aspectFill: CGSize(width: size.width-inset.x*scale,height: size.height-inset.y*scale))
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

public extension UIImage {
    convenience init?(color: UIColor, size: CGSize) {
        let drawRect = CGRect(origin: .zero, size: size)
        guard let result = UIGraphicsImageRenderer(size: size).imageWithCurrentContext(actions: { (ctx) in
            ctx.setFillColor(color.cgColor)
            ctx.fill(drawRect)
        })?.cgImage else { return nil }
        self.init(cgImage: result)
    }
    
    convenience init?(path: UIBezierPath, fillColor: UIColor? = nil, strokeColor: UIColor? = nil, strokeWidth: CGFloat? = nil) {
        let lineWidth: CGFloat = strokeWidth ?? (strokeColor != nil ? 1 : 0)
        let pathBounds = path.bounds
        
        guard let result = UIGraphicsImageRenderer(size: CGSize(width: pathBounds.minX + pathBounds.maxX, height: pathBounds.minY + pathBounds.maxY)).imageWithCurrentContext(actions: { (ctx) in
            if let color = fillColor {
                ctx.setFillColor(color.cgColor)
                path.fill()
            }
            if let color = strokeColor {
                ctx.setLineWidth(lineWidth)
                ctx.setStrokeColor(color.cgColor)
                path.stroke()
            }
        })?.cgImage else { return nil }
        self.init(cgImage: result, scale: 1, orientation: .up)
    }
}
