//
//  StyleArt.swift
//  StyleArts
//
//  Created by Levin  on 17/10/17.
//  Copyright © 2017 Levin . All rights reserved.
//

import Foundation
import CoreML
import UIKit

///ArtStyle enum defines the number of styles present in StyleArt
enum StyleArtStyle:Int {
    case Mosaic
    case Scream
    case Muse
    case Udanie
    case Candy
    case Feathers
}

///Style Art class process images using COREML on a set of pre trained machine learning models and convert them to Art style.
class StyleArt{
    
    //MARK:- Properties
    let models:[StyleArtStyle:MLModel] = [
        .Muse: FNS_La_Muse_1().model
        , .Candy: FNS_Candy_1().model
        , .Feathers: FNS_Feathers_1().model
        , .Udanie: FNS_Udnie_1().model
        , .Mosaic: FNS_Mosaic_1().model
        , .Scream: FNS_The_Scream_1().model
    ]
    
    //Height constant for image processing
    let definedImageSize = 720
    
    //MARK:- Shared singleton
    ///Shared Instance of StyleArt class
    static let shared = StyleArt()
    
    //MARK:- Image Processing
    ///Process method performs the style art transfer of the given image based on the style chosen and returns the result in closure.
    /// - parameter image:          The Image on which styles are applied.
    /// - parameter ArtStyle:       The styles present in ArtStyle enum.
    /// - parameter compeletion:    The closure which return the final processed image,if the   operation is failed it will return nil.
    func process(image:UIImage,style:StyleArtStyle,compeletion:(_ result:UIImage?)->()){
        
        if let model = models[style]
            , let pixelBufferd = image.pixelBuffer(width: definedImageSize, height: definedImageSize) {
            
            let input = StyleArtInput(input:pixelBufferd)
            let outFeatures = try! model.prediction(from: input)
            let output = outFeatures.featureValue(for: "outputImage")!.imageBufferValue!
            if let result = UIImage(pixelBuffer: output) {
                print("Done");
                compeletion(result)
            }else{
                print("Failed");
                compeletion(nil)
            }
            
        }
    }
    //MARK:- Private Helper Functions
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
    ///Method which converts given CGImage to CVPixelBuffer.
    private func pixelBuffer(cgImage: CGImage, width: Int, height: Int) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
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
