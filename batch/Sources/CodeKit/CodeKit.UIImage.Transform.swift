//
// Created by BLACKGENE on 29/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    func flipHorizontally() -> UIImage {
        return withHorizontallyFlippedOrientation()
    }

    func flipVertically() -> UIImage {
        return UIGraphicsImageRenderer(size: size, format: imageRendererFormat).image { (ctx) in
            guard let cgImage = self.cgImage else { return }
            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
            ctx.cgContext.scaleBy(x: 1, y: -1)
        }
    }

    func rotate(by degrees: CGFloat) -> UIImage {
        return applyTransform(CGAffineTransform(rotationAngle: degrees.degreesToRadians))
    }

    func rotate(with transform: CGAffineTransform) -> UIImage {
        let renderSize = size.applying(transform).magnitude
        return UIGraphicsImageRenderer(size: renderSize, format: imageRendererFormat).image { (ctx) in
            ctx.cgContext.translateBy(x: renderSize.width / 2, y: renderSize.height / 2)
            ctx.cgContext.rotate(by: transform.radians)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            if let cgImage = self.cgImage {
                ctx.cgContext.draw(cgImage, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
            }
        }
    }

    func applyTransform(_ transform: CGAffineTransform) -> UIImage {
        let renderSize = size.applying(transform).magnitude
        return UIGraphicsImageRenderer(size: renderSize, format: imageRendererFormat).image { (ctx) in
            ctx.cgContext.translateBy(x: renderSize.width / 2, y: renderSize.height / 2)
            ctx.cgContext.concatenate(transform)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            if let cgImage = self.cgImage {
                ctx.cgContext.draw(cgImage, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
            }
        }
    }
}
