//
// Created by BLACKGENE on 2018-10-11.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Accelerate
import CoreVideo
import CoreGraphics

public extension CGImage{
    func re(size:CGSize) -> CGImage? {
        let cgImage = self

        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: nil,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)
        var sourceBuffer = vImage_Buffer()
        defer {
            sourceBuffer.data.deallocate()
        }

        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }

        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)

        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }

        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return nil }

        return destCGImage
    }

    var size:CGSize{
        return CGSize(width:width, height: height)
    }

    func pixelBuffer() -> CVPixelBuffer? {

        var pxbuffer: CVPixelBuffer?

        guard let dataProvider = dataProvider else {
            return nil
        }

        let dataFromImageDataProvider = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, dataProvider.data)

        CVPixelBufferCreateWithBytes(
                kCFAllocatorDefault,
                width,
                height,
                kCVPixelFormatType_32ARGB,
                CFDataGetMutableBytePtr(dataFromImageDataProvider),
                bytesPerRow,
                nil,
                nil,
                nil,
                &pxbuffer
        )

        return pxbuffer
    }

}

public extension CGImage{
    //INFO: Real Device:
    /*
        -- FIRST PROCESSING
        measured at System.swift - measure#44 :: 0.007345875000000001s - this
        measured at System.swift - measure#44 :: 0.12329795833333335s  - CImage.applyingGaussianBlur(sigma: 100)

        -- N(th) PROCESSING
        measured at System.swift - measure#44 :: 0.0035489583333333337s
        measured at System.swift - measure#44 :: 0.011435875s

        measured at System.swift - measure#44 :: 0.0025405833333333335s
        measured at System.swift - measure#44 :: 0.011500125s
    */
    func blur() -> CGImage?{
        let kernelLength = 51
        var format = _format
        var sourceBuffer = _sourceBuffer
        var destinationBuffer = vImage_Buffer()

        vImageBuffer_Init(&destinationBuffer,
                sourceBuffer.height,
                sourceBuffer.width,
                format.bitsPerPixel,
                vImage_Flags(kvImageNoFlags))

        vImageTentConvolve_ARGB8888(&sourceBuffer,
                &destinationBuffer,
                nil,
                0, 0,
                UInt32(kernelLength),
                UInt32(kernelLength),
                nil,
                vImage_Flags(kvImageEdgeExtend))

        let result = vImageCreateCGImageFromBuffer(
                &destinationBuffer,
                &format,
                nil,
                nil,
                vImage_Flags(kvImageNoFlags),
                nil).takeRetainedValue()

        free(destinationBuffer.data)
        free(sourceBuffer.data)

        return result
    }

    private var _format: vImage_CGImageFormat {
        guard let sourceColorSpace = self.colorSpace else {
            fatalError("Unable to get color space")
        }

        return vImage_CGImageFormat(
                bitsPerComponent: UInt32(bitsPerComponent),
                bitsPerPixel: UInt32(bitsPerPixel),
                colorSpace: Unmanaged.passRetained(sourceColorSpace),
                bitmapInfo: bitmapInfo,
                version: 0,
                decode: nil,
                renderingIntent: renderingIntent)
    }

    private var _sourceBuffer: vImage_Buffer {
        var sourceImageBuffer = vImage_Buffer()
        var format = _format

        vImageBuffer_InitWithCGImage(&sourceImageBuffer,
                &format,
                nil,
                self,
                vImage_Flags(kvImageNoFlags))

        var scaledBuffer = vImage_Buffer()

        vImageBuffer_Init(&scaledBuffer,
                sourceImageBuffer.height / 4,
                sourceImageBuffer.width / 4,
                format.bitsPerPixel,
                vImage_Flags(kvImageNoFlags))

        vImageScale_ARGB8888(&sourceImageBuffer,
                &scaledBuffer,
                nil,
                vImage_Flags(kvImageNoFlags))
        
        free(sourceImageBuffer.data)

        return scaledBuffer
    }
}
