import Foundation
import CoreML
import UIKit

enum MLArtStyle: Int, Codable{
    case Mosaic
    case Scream
    case Muse
    case Udanie
    case Candy
    case Feathers

    var name:String{
        return String(describing: self)
    }
}

class CIMLArtFilter: CIFilter {
    var style: MLArtStyle = .Mosaic

    init(style: MLArtStyle) {
        super.init()
        self.name = style.name
        self.style = style
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc dynamic var inputImage : CIImage?

    override var outputImage: CIImage? {
        return autoreleasepool {
            guard let image = value(forKey: kCIInputImageKey) as? CIImage
            , let uiImage = image.asUIImage else {
                return nil
            }

            //TODO: directly process CIImage
            if let resultImage = MLArtProcessor().process(image: uiImage, style: style){
                return CIImage(image: resultImage)
            }

            return nil
        }
    }
}

class MLArtProcessor {

    static let definedImageSize = CGSize(width:720, height:720)
    
    private func acquireModel(style:MLArtStyle) -> MLModel{
        return autoreleasepool {
            switch(style){
            case .Muse:
                return FNS_La_Muse_1().model
            case .Candy:
                return FNS_Candy_1().model
            case  .Feathers:
                return FNS_Feathers_1().model
            case  .Udanie:
                return FNS_Udnie_1().model
            case  .Mosaic:
                return FNS_Mosaic_1().model
            case  .Scream:
                return FNS_The_Scream_1().model
            }
        }
    }

    func process(image: UIImage, style: MLArtStyle) -> UIImage? {

        let model = acquireModel(style:style)
        let imageSize = type(of: self).definedImageSize
        
        if let pixelBufferd = image.pixelBuffer(width: Int(imageSize.width), height: Int(imageSize.height)) {

            let input = MLArtProcessorInput(input: pixelBufferd)
            let outFeatures = try! model.prediction(from: input)
            let output = outFeatures.featureValue(for: "outputImage")!.imageBufferValue!

            return UIImage(pixelBuffer: output)
        }

        return nil
    }

    private func stylizeImage(cgImage: CGImage, model: MLModel) -> CGImage {
        let imageSize = type(of:self).definedImageSize
        let input = MLArtProcessorInput(input: pixelBuffer(cgImage: cgImage, width: Int(imageSize.width), height: Int(imageSize.height)))
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


private class MLArtProcessorInput: MLFeatureProvider {

    /// input as color (kCVPixelFormatType_32BGRA) image buffer, 720 pixels wide by 720 pixels high
    var input: CVPixelBuffer

    var featureNames: Set<String> {
        get {
            return ["inputImage"]
        }
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "inputImage") {
            return MLFeatureValue(pixelBuffer: input)
        }
        return nil
    }

    init(input: CVPixelBuffer) {
        self.input = input
    }
}
