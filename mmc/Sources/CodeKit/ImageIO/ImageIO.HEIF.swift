//
// Created by BLACKGENE on 12/04/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import UIKit
import AVFoundation.AVMediaFormat

@available(iOS 11.0, *)
func UIImageHEIFRepresentation(_ image: UIImage, _ compression: Float) -> Data? {
    guard let cgImage = image.cgImage else { return nil }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, AVFileType.heic.rawValue as CFString, 1, nil) else {
        return nil
    }

    let options: NSDictionary = [kCGImageDestinationLossyCompressionQuality: compression]
    CGImageDestinationAddImage(destination, cgImage, options)
    CGImageDestinationFinalize(destination)

    return data as Data
}