//
//  CodeKit.UIGraphicsImageRenderer.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 5. 2..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

extension UIGraphicsImageRenderer {
    func imageWithCurrentContext(actions: (CGContext) -> Void) -> UIImage? {
        var result: UIImage?
        if let imageRendererFormat = format as? UIGraphicsImageRendererFormat {
            UIGraphicsBeginImageContextWithOptions(format.bounds.size, imageRendererFormat.opaque, imageRendererFormat.scale)
        }
        else {
            UIGraphicsBeginImageContextWithOptions(format.bounds.size, false, 1)
        }
        actions(UIGraphicsGetCurrentContext() ?? UIGraphicsImageRendererContext().cgContext)
        result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
