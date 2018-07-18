//
// Created by BL?ACKGENE on 10.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit
import CocoaImageHashing
import MetalPerformanceShaders
import MetalKit
import Vision
import FirebaseMLVision

protocol _GarbageDetector: AsyncProcessor where Self.OutputType==Bool {}

protocol _PHAssetGarbageDetector: _GarbageDetector where Self.InputType==PHAsset {}

class PHAssetGarbageDetector : NSObject, _PHAssetGarbageDetector{
    required public override init() {}

    static var identifier: String {
        return String(describing:self)
    }

    class var label:String{
        return "Undefined"
    }

    class var iconImageName:String?{
        return nil
    }

    func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return nil
    }
}

class PHAssetGarbageDetector_Screenshots : PHAssetGarbageDetector{
    override class var label:String{
        return "Screenshots".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return input.mediaType == .image && input.mediaSubtypes.contains(.photoScreenshot) //FIXME: always true??
    }
}

class PHAssetGarbageDetector_Flashlight: PHAssetGarbageDetector{
    override class var label:String{
        return "Flashlight".localized
    }

    private let firedFlags = Set<Int>([
        0x1//=Fired
        ,0x5//=Fired, Return not detected
        ,0x7//=Fired, Return detected
        ,0x9//=On, Fired
        ,0x19//=Auto, Fired
        ,0x1d//=Auto, Fired, Return not detected
        ,0x1f//=Auto, Fired, Return detected
        ,0x41//=Fired, Red-eye reduction
        ,0x45//=Fired, Red-eye reduction, Return not detected
        ,0x47//=Fired, Red-eye reduction, Return detected
        ,0x59//=Auto, Fired, Red-eye reduction
        ,0x5d//=Auto, Fired, Red-eye reduction, Return not detected
        ,0x5f//=Auto, Fired, Red-eye reduction, Return detected
    ])

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        guard input.mediaType == .image else { return false }

        let option = PHContentEditingInputRequestOptions()
        option.isNetworkAccessAllowed = false
        option.canHandleAdjustmentData = { _ -> Bool in
            return false
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        if let data = input.requestImageData(options: options, asyncSignal).data{
            if let lensMake = data.getMetadataValue(dictionary: ImageMetadata.Dictionary.Exif, property: ImageMetadata.Property.ExifLensMake) as? String{
                if lensMake.trimmed == "Apple", let flashValue = data.getMetadataValue(dictionary: ImageMetadata.Dictionary.Exif, property: ImageMetadata.Property.ExifFlash) as? Int{
                    return firedFlags.contains(flashValue)
                }
            }
        }

        return false
    }
}

class PHAssetGarbageDetector_TooCloseupFace: PHAssetGarbageDetector {
    override class var label:String{
        return "Too Close-up Face".localized
    }

    private let allowedMinFaceBoundSizeRatio:CGFloat = 0.4

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        guard let faces = input.asCIImage?.asFaceBoundingBoxes else{
            return false
        }

        let rect = faces.biggest()
        return rect.width*rect.height>=self.allowedMinFaceBoundSizeRatio
    }
}



class PHAssetGarbageDetector_VideosWithoutSound: PHAssetGarbageDetector{
    override class var label:String{
        return "Videos Without Sound".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        guard input.mediaType == .video else { return false }

        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.isNetworkAccessAllowed = false
        videoRequestOptions.deliveryMode = .automatic

        var haveNotSound = false
        asyncSignal.begin()
        PHImageManager.default().requestAVAsset(forVideo: input, options: videoRequestOptions, resultHandler: { (asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable: Any]?) -> Void in
            haveNotSound = asset?.tracks(withMediaType: .audio).count ?? 0 == 0
            asyncSignal.end()
        })
        asyncSignal.waitUntilEnd()

        return haveNotSound
    }
}

class PHAssetGarbageDetector_TooSlowShutterSpeed: PHAssetGarbageDetector{
    override class var label:String{
        return "Too Slow Shutter Speed".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
//        guard input.mediaType == .image else { return false }

        let option = PHContentEditingInputRequestOptions()
        option.isNetworkAccessAllowed = false
        option.canHandleAdjustmentData = { _ -> Bool in
            return false
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false

        if let data = input.requestImageData(options: options, asyncSignal).data{
            //ShutterSpeedValue
            //ExposureTime
            if let v = data.getMetadataValue(dictionary: ImageMetadata.Dictionary.Exif, property: ImageMetadata.Property.ExifExposureTime) as? Double{
                //ShutterSpeed=-log2(ExposureTime).
                return v >= 0.25
            }

            //OR

            if let v = data.getMetadataValue(dictionary: ImageMetadata.Dictionary.Exif, property: ImageMetadata.Property.ExifShutterSpeedValue) as? Double{
                return v < 2.1
            }
        }

        return false
    }
}

class PHAssetGarbageDetector_VideosShorterThan1Sec: PHAssetGarbageDetector{
    override class var label:String{
        return "Videos Shorter Than One Second".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        //TODO: user defined custom duration
        return input.mediaType == .video && input.duration <= 1
    }
}

class PHAssetGarbageDetector_NotByiOSCamera: PHAssetGarbageDetector{
    override class var label:String{
        return "Not By iOS Camera".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        guard input.mediaType == .image else { return false }

        let option = PHContentEditingInputRequestOptions()
        option.isNetworkAccessAllowed = false
        option.canHandleAdjustmentData = { _ -> Bool in
            return false
        }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        if let data = input.requestImageData(options: options, asyncSignal).data{
            if let v = data.getMetadataValue(dictionary: ImageMetadata.Dictionary.Exif, property: ImageMetadata.Property.ExifLensMake) as? String{
                if v.trimmed == "Apple"{
                    return false
                }
            }
        }
        return true
    }
}

/*
    Similarity
*/
class PHAssetGarbageDetector_Similarity : PHAssetGarbageDetector{
    override class var label:String{
        return "Similarity".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return self.detectSimilarAsset(input)
    }

    private var targetAssets = [PHAsset]()
    private let imageHashing = OSImageHashing.sharedInstance()

    private func detectSimilarAsset(_ asset: PHAsset) -> Bool {
        // https://github.com/ameingast/cocoaimagehashing/
        let timeClustering: TimeInterval = 60 // 1 minute

        var hasSimilar = false
        for targetAsset in targetAssets[..<min(targetAssets.count, 20)] {
            guard let fromDate = targetAsset.creationDate, let toDate = asset.creationDate, fromDate.timeIntervalSince(toDate).magnitude < timeClustering else {
                continue
            }

            guard let fromData = targetAsset.requestThumbnailImage(targetSize: CGSize(width: 100, height: 100))?.asData, let toData = asset.requestThumbnailImage(targetSize: CGSize(width: 100, height: 100))?.asData else { continue }

            let fromHash = imageHashing.hashImageData(fromData)
            let toHash = imageHashing.hashImageData(toData)
            let distance = imageHashing.hashDistance(fromHash, to: toHash)

            if distance < imageHashing.hashDistanceSimilarityThreshold(withProvider: .dHash) {
                hasSimilar = true
                break
            }
        }

        targetAssets.insert(asset, at: 0)

        return hasSimilar
    }
}

class PHAssetGarbageDetector_Similarity_t : PHAssetGarbageDetector{
    override class var label:String{
        return "Similarities".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return self.detectSimilarAsset(input)
    }

    private var targetAssets = [PHAsset:Set<String>]()
    private let imageHashing = OSImageHashing.sharedInstance()

    private var similarCache = [String:OSHashDistanceType]()

    let sep = "=="

    private func isDistanceSimilar(_ distance:OSHashDistanceType) -> Bool{
        return distance < imageHashing.hashDistanceSimilarityThreshold(withProvider: .dHash)
    }

    private func getDistance(_ asset1:PHAsset, _ asset2:PHAsset) -> OSHashDistanceType{
        let keySrc = [asset1.localIdentifier,asset2.localIdentifier]
        let key = keySrc.joined(separator: sep)

        if let sim = similarCache[key]{
            return sim
        }else if let sim = similarCache[keySrc.reversed().joined(separator: sep)]{
            return sim
        }

//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//
//        var _data1: Data?
//        PHImageManager.default().requestImageData(for: asset1, options: options) { data, _, _, _ in
//            _data1 = data
//        }
//
//        var _data2: Data?
//        PHImageManager.default().requestImageData(for: asset2, options: options) { data, _, _, _ in
//            _data2 = data
//        }
//        guard let data1 = _data1, let data2 = _data2 else {
//            return OSHashDistanceType.max
//        }

        guard let data1 = asset1.requestThumbnailImage(targetSize: CGSize(width: 150, height: 150))?.asData
        , let data2 = asset2.requestThumbnailImage(targetSize: CGSize(width: 150, height: 150))?.asData  else {
            return OSHashDistanceType.max
        }

        let hash1 = imageHashing.hashImageData(data1)
        let hash2 = imageHashing.hashImageData(data2)
        let distance12 = imageHashing.hashDistance(hash1, to: hash2)
        let distance21 = imageHashing.hashDistance(hash2, to: hash1) //TODO: remove if not differennt between 12, 21

        let distance:OSHashDistanceType = (distance12+distance21)/2

        print("distance12",distance)

        similarCache[key] = distance
        return distance
    }

    private func detectSimilarAsset(_ asset: PHAsset) -> Bool {
        // https://github.com/ameingast/cocoaimagehashing/
        let id = asset.localIdentifier

        if targetAssets.keys.count == 0{
            targetAssets[asset] = Set<String>()
            return false
        }

        for set in targetAssets.values{
            if set.contains(id){
                return true
            }
        }

        for hostAsset in targetAssets.keys{
            if hostAsset.localIdentifier == id{
                return false
            }

            if isDistanceSimilar(getDistance(hostAsset, asset)){
                if targetAssets[hostAsset] == nil{
                    targetAssets[hostAsset] = Set<String>()
                }
                targetAssets[hostAsset]?.insert(id)
                return true
            }
        }

        targetAssets[asset] = Set<String>()
        return false
    }
}

/*
    Blurry
*/
//FIXME: Blurry is not detect only Blurred.
class PHAssetGarbageDetector_Blurry: PHAssetGarbageDetector{
    override class var label:String{
        return "Blur Rate".localized
    }

    override func process(input: PHAsset,_ asyncSignal: AsyncWaitSignalable) -> Bool? {
        return self.detectBlurryImage(input)
    }

    private func detectBlurryImage(_ asset: PHAsset) -> Bool {
        // https://www.pyimagesearch.com/2015/09/07/blur-detection-with-opencv/
        // https://stackoverflow.com/questions/46893198/detecting-if-image-is-blurred-using-opencv
        //
        guard
                asset.imageType == .stillImage,
                let device = MTLCreateSystemDefaultDevice(),
                let commandQueue = device.makeCommandQueue(),
                let commandBuffer = commandQueue.makeCommandBuffer(),
                let ciImage = asset.asCIImage
                else { return false }


//        if let face = croppedFaceGroup(ciImage) {
//            ciImage = face
//        }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(ciImage.extent.width), height: Int(ciImage.extent.height), mipmapped: false)
        textureDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]

        guard
                let sourceTexture = device.makeTexture(descriptor: textureDescriptor),
                let binaryTexture = device.makeTexture(descriptor: textureDescriptor),
                let laplacianTexture = device.makeTexture(descriptor: textureDescriptor)
                else { return false }

        ImageAlignment.sharedCIContext.render(ciImage, to: sourceTexture, commandBuffer: commandBuffer, bounds: ciImage.extent, colorSpace: CGColorSpaceCreateDeviceRGB())

        MPSImageLaplacian(device: device).encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: laplacianTexture)
        MPSImageThresholdBinary(device: device, thresholdValue: 0.4, maximumValue: 1, linearGrayColorTransform: nil).encode(commandBuffer: commandBuffer, sourceTexture: laplacianTexture, destinationTexture: binaryTexture)

        let numberOfHistogramEntries = 256

        var histogramInfo = MPSImageHistogramInfo(
                numberOfHistogramEntries: numberOfHistogramEntries,
                histogramForAlpha: false,
                minPixelValue: vector_float4(0, 0, 0, 0),
                maxPixelValue: vector_float4(1, 1, 1, 1))

        let histogram = MPSImageHistogram(device: device, histogramInfo: &histogramInfo)
        let bufferLength = histogram.histogramSize(forSourceFormat: binaryTexture.pixelFormat)
        guard let histogramInfoBuffer = device.makeBuffer(length: bufferLength, options: []) else { return false }

        histogram.encode(to: commandBuffer, sourceTexture: binaryTexture, histogram: histogramInfoBuffer, histogramOffset: 0)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let histogramContents = histogramInfoBuffer.contents().bindMemory(to: Float.self, capacity: numberOfHistogramEntries)

        let threshold: Float = 0.00000000000000000000000000000000000000000031 //TODO: this is a manual threshold
        let numberOfWhitePixels = histogramContents[numberOfHistogramEntries - 1]

        return numberOfWhitePixels < threshold
    }

    private func croppedFaceGroup(_ image: CIImage) -> CIImage? {
        if let unionBound = image.asFaceBoundingBoxes?.union(), unionBound.width * unionBound.height > 0.2{

            let transform = CGAffineTransform(scaleX: image.extent.width, y: image.extent.height)
            return image.cropped(to: unionBound.applying(transform))
        }
        return nil
    }
}
