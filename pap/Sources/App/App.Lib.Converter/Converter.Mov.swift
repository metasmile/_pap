//
// Created by BLACKGENE on 04/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO
import MobileCoreServices

struct MovConverterOption {
    var exportSize: CGSize = .zero
    
    static var `default`: MovConverterOption {
        return MovConverterOption(exportSize: CGSize(width: 1920, height: 1080))
    }
    
    static func preset(_ quality: ExportQualityType, with asset: PHAsset) -> MovConverterOption {
        var optionPreset = MovConverterOption.default
        optionPreset.exportSize = scaleSize(asset.pixelSize, with: quality)
        return optionPreset
    }
    
    private static func scaleSize(_ size: CGSize, with quality: ExportQualityType) -> CGSize {
        guard quality != .original else { return size }
        
        let maximumSize = max(640, size.width, size.height)
        let sizePhases: [CGFloat] = [3840, 1920, 1280, 960, 640, 480, 320, 240]
        let indexOfQuality: ((ExportQualityType) -> Int) = { type in
            switch type {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            default: return NSNotFound
            }
        }
        
        let allowedSizes = sizePhases.filter({ maximumSize > $0 })
        let baseSize = allowedSizes[indexOfQuality(quality)]
        let aspectRatio = size.width / size.height
        
        if aspectRatio < 1 {
            return CGSize(width: Int(baseSize * aspectRatio), height: Int(baseSize))
        }
        else {
            return CGSize(width: Int(baseSize), height: Int(baseSize / aspectRatio))
        }
    }
}

protocol MovConverter: Converter {}

extension MovConverter {
    static var direction: ConvertingDirection {
        return ConvertingDirection(from: .any, to: .mov)
    }
}

class MovConverter_Gif: OptionableConverterBase<MovConverterOption>, MovConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.gif, to:.mov) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {

        var urls:[(URL, Double)]?

        async.begin()
        PHImageManager.default().requestImageData(for: source.asset, options: nil) { data, s, orientation, dictionary in
            urls = data?.extractAnimatedImageURLsAsGIF()
            async.end()
        }
        async.waitUntilEnd()

        if let urls = urls, let url = self.buildVideo(urls: urls, outputSize: options?.exportSize, async) {
            return PHAssetResourceFinalizingOutput(resources: [(resourceType: .video, url: url)])
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .animatedGIF
    }
    
    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumAnimated
    }
}

class MovConverter_Burst: OptionableConverterBase<MovConverterOption>, MovConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.burst, to:.mov) }
    
    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {

        if let urls = self.extractBurstImageURLs(source: source, async), let url = self.buildVideo(urls: urls, outputSize: options?.exportSize, async) {
            return PHAssetResourceFinalizingOutput(resources: [(resourceType: .video, url: url)])
        }

        return nil
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .burst
    }
    
    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumBursts
    }
}

struct MovConverter_LivePhoto: MovConverter {
    static var direction: ConvertingDirection { return ConvertingDirection(from:.livephoto, to:.mov) }

    func convert(source: AppAsset, _ async: AsyncManualSignalable) -> PHAssetResourceFinalizingOutput? {

        var exportedlivePhoto: PHLivePhoto?

        async.begin()

        let livePhotoOptions = PHLivePhotoRequestOptions()

        livePhotoOptions.deliveryMode = .highQualityFormat
        let req_livephoto = PHImageManager.default().requestLivePhoto(for: source.asset
                , targetSize: .zero
                , contentMode: .default
                , options: livePhotoOptions
                , resultHandler: { livePhoto, info in

            exportedlivePhoto = livePhoto
            async.end()

        })
        source.requestIDs.append(PHAssetRequestID(forImage: req_livephoto))
        async.waitUntilEnd()

        guard let livePhoto = exportedlivePhoto else {
            return nil
        }

        let resources = PHAssetResource.assetResources(for: livePhoto)

        guard let videoResource = resources.first(where: { $0.type == PHAssetResourceType.pairedVideo }),
              let _ = resources.first(where: { $0.type == PHAssetResourceType.photo }) else {
            return nil
        }

        var videoData = Data()
        var resultURL:URL?

        async.begin()

        let req_data = PHAssetResourceManager.default().requestData(for: videoResource, options: nil, dataReceivedHandler: { (data) in
            videoData.append(data)

        }) { (error) in
            if error == nil{
                let pairedVideoFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString)_pairedVideo.mov")
                try? FileManager.default.removeItem(at: pairedVideoFileURL)
                try? videoData.write(to: pairedVideoFileURL, options: Data.WritingOptions.atomicWrite)

                resultURL = pairedVideoFileURL
            }
            async.end()
        }
        source.requestIDs.append(PHAssetRequestID(forResourceData: req_data))
        async.waitUntilEnd()

        guard let url = resultURL else { return nil }
        return PHAssetResourceFinalizingOutput(resources: [(resourceType: .video, url: url)])
    }

    static func canPerformWith(source: AppAsset) -> Bool {
        return source.asset.imageType == .livePhoto
    }
    
    static var performAssetCollectionType: PHAssetCollectionSubtype? {
        return .smartAlbumLivePhotos
    }
}
