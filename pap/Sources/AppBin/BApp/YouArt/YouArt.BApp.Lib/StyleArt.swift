import Foundation
import CoreML
import UIKit

enum StyleArtStyle: Int {
    case Mosaic
    case Scream
    case Muse
    case Udanie
    case Candy
    case Feathers
}

class StyleArt {

    private let models: [StyleArtStyle: MLModel] = [
        .Muse: FNS_La_Muse_1().model
        , .Candy: FNS_Candy_1().model
        , .Feathers: FNS_Feathers_1().model
        , .Udanie: FNS_Udnie_1().model
        , .Mosaic: FNS_Mosaic_1().model
        , .Scream: FNS_The_Scream_1().model
    ]

    let definedImageSize = 720

    static let shared = StyleArt()

    func process(image: UIImage, style: StyleArtStyle, compeletion: (_ result: UIImage?) -> ()) {

        if let model = models[style]
        , let pixelBufferd = image.pixelBuffer(width: definedImageSize, height: definedImageSize) {

            let input = StyleArtInput(input: pixelBufferd)
            let outFeatures = try! model.prediction(from: input)
            let output = outFeatures.featureValue(for: "outputImage")!.imageBufferValue!
            if let result = UIImage(pixelBuffer: output) {
                print("Done");
                compeletion(result)
            } else {
                print("Failed");
                compeletion(nil)
            }

        }
    }

    private func stylizeImage(cgImage: CGImage, model: MLModel) -> CGImage {
        let input = StyleArtInput(input: pixelBuffer(cgImage: cgImage, width: definedImageSize, height: definedImageSize))
        let outFeatures = try! model.prediction(from: input)
        let output = outFeatures.featureValue(for: "outputImage")!.imageBufferValue!
        CVPixelBufferLockBaseAddress(output, .readOnly)
        let width = CVPixelBufferGetWidth(output)
        let height = CVPixelBufferGetHeight(output)
        let data = CVPixelBufferGetBaseAddress(output)!

        let outContext = CGContext(data: data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(output),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)!
        let outImage = outContext.makeImage()!
        CVPixelBufferUnlockBaseAddress(output, .readOnly)

        return outImage
    }

    private func pixelBuffer(cgImage: CGImage, width: Int, height: Int) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        if status != kCVReturnSuccess {
            fatalError("Cannot create pixel buffer for image")
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
        let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer!
    }
}
