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
    
    static func preset(_ quality: ConverterQualityPreset, with asset: PHAsset) -> JpgConverterOption {
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

protocol JpgConverter: Converter, ConverterCapability {}
extension JpgConverter{
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .jpeg)
    }
}

class JpgConverter_ScreenshotPng: OptionableConverterBase<JpgConverterOption>, JpgConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.png_screenshot, to:.jpeg) }

    static let supportedPresets = ConverterQualityPreset.originalExcluded
    
    func convert(source: AppAsset, cancellation: (() -> Bool)?, progressHandler: PHAssetEditableProgressHandler?, _ async: AsyncWaitSignalable) -> Any? {

        var result:Any?

        let quality:CGFloat = options?.compressionQuality ?? 0.7

        async.begin()
        let requestId = PHImageManager.default().requestImageData(for: source.asset, options: nil) { data, s, orientation, dictionary in

            for r in source.asset.resources{
                let url = URL(fileURLWithPath: r.originalFilename)
                if UTI(withURL: url) == UTI.png, let data = data {
                    let fileURL = FileURL.temp(url.deletingPathExtension().lastPathComponent, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())

                    do{
                        if let image = UIImage(data: data)
                        , let imageData = image.jpegData(compressionQuality: quality){
                            try? FileManager.default.removeItem(at: fileURL)
                            try imageData.write(to: fileURL)
                            result = fileURL
                        }

                    }catch _ {}
                    break
                }
            }

            async.end()
        }

        source.appendRequestId(PHAssetRequestID(forImage: requestId))
        async.waitUntilEnd()
        return result
    }

    static func canPerformWith(asset: PHAsset) -> Bool {
        return asset.mediaSubtypes.contains(.photoScreenshot)
    }

}
