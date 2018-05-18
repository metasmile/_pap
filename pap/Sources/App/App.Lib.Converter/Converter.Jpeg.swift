//
// Created by BLACKGENE on 08/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

struct JpgConverterOption {
    var compressionQuality: CGFloat = 0.7
    
    static var `default`: JpgConverterOption {
        return JpgConverterOption(compressionQuality: 0.7)
    }
    
    static func preset(_ quality: ExportQualityType, with asset: PHAsset) -> JpgConverterOption {
        var options = JpgConverterOption.default
        switch quality {
        case .high: options.compressionQuality = 1.0
        case .medium: options.compressionQuality = 0.7
        case .low: options.compressionQuality = 0.5
        default: break
        }
        return options
    }
}

protocol JpgConverter: Converter {}
extension JpgConverter{
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .jpeg)
    }
}

class JpgConverter_ScreenshotPng: OptionableConverterBase<JpgConverterOption>, JpgConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.png_screenshot, to:.jpeg) }
    
    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var result:Any?

        let quality:CGFloat = options?.compressionQuality ?? 0.7

        async.begin()
        PHImageManager.default().requestImageData(for: source.asset, options: nil) { data, s, orientation, dictionary in

            for r in source.asset.resources{
                let url = URL(fileURLWithPath: r.originalFilename)
                if url.pathExtension.lowercased() == "png", let data = data {
                    let fileURL = url.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent.asURLInTemporaryDirectory

                    do{
                        if let image = UIImage(data: data)
                        , let imageData = UIImageJPEGRepresentation(image, quality){
                            try? FileManager.default.removeItem(at: fileURL!)
                            try imageData.write(to: fileURL!)

                            result = fileURL
                        }

                    }catch _ {}
                    break
                }
            }

            async.end()
        }

        async.waitUntilEnd()
        return result
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.mediaSubtypes.contains(.photoScreenshot)
    }

}
