//
// Created by BLACKGENE on 08/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

protocol JpgConverter: Converter {}
extension JpgConverter{
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .jpeg)
    }
}

struct JpgConverter_ScreenshotPng: JpgConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.png_screenshot, to:.jpeg) }

    init() {}

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var result:Any?

        let quality = 0.7

        async.begin()
        PHImageManager.default().requestImageData(for: source.asset, options: nil) { data, s, orientation, dictionary in

            for r in source.asset.resources{
                let url = URL(fileURLWithPath: r.originalFilename)
                if url.pathExtension.lowercased() == "png", let data = data {
                    let fileURL = url.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent.asURLInTemporaryDirectory

                    do{
                        if let image = UIImage(data: data)
                        , let imageData = UIImageJPEGRepresentation(image, quality){
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
