//
// Created by BLACKGENE on 02/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

//INFO: mainly focusing on GIF, at first.

import Foundation
import UIKit
import MobileCoreServices
import Photos

public class Converter: BApp,
        AppDockControllableApp,
        PHAssetFinalizableApp,
        PhotoPickerCollectionViewDisplayableApp,
        PhotoPickerViewControllerDelegatableApp {

    public static let taskType:Taskable.Type = ConverterTask.self
    public static let paramType:TaskParamable.Type = AppAsset.self

    public static var configure:(() -> GIFMakerAppConfig)?

    @objc dynamic
    public private(set) lazy var config: GIFMakerAppConfig? = GIFMaker.configure?()
//    public private(set) lazy var dockContent: AppDockContent? = GIFMakerAppDockContent()
    public private(set) var dockContent: AppDockContent?

    public static let info = AppInfo(
            identifier: "com.stells.batch.converter"
            , version: "1.0"
            , phase: .develop
            , appType: Converter.self
            , displayName: "Converter" // 1 - 1
            , icon: R.image.photosFilterAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public init() {}

    public var doneButtonTitle: String? {
        return "Convert".localized
    }

    public func shouldSelect(item: PHAssetItem<ImageEditStateValue>) -> Bool {
        let t = item.asset.mediaType
        let it = item.asset.imageType
        let st = item.asset.mediaSubtypes
//        let u = item.asset.uniformTypeIdentifier

        if it == .animatedGIF || it == .burst{
            return true
        }

        if t == PHAssetMediaType.video {
           return true
        }

        if t == PHAssetMediaType.image && (st.contains(.photoLive) || st.contains(.videoTimelapse)){
            return true
        }

        return false
    }

    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public var finalizingPresets: [PHAssetFinalizingPresets]? {
        return nil
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){

    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultItems = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { ($0.result as? ConverterPHAssetResult)?.result }

        var shareItems:[Any]? = resultItems

//        asyncSignal.begin()
//        let builder = TimeLapsBuilder(imagePaths: imageFiles)
//        builder.build({ progress in  }, success: { url in
//            shareItem = url
//
//            asyncSignal.end()
//
//        }, failure: { error in
//            print(error)
//            asyncSignal.end()
//        })
//        asyncSignal.waitUntilEnd()


//        asyncSignal.begin()
//        let lpWriter = LivePhotoWriter()
//
//        lpWriter.saveLivePhotoFromImages(paths: imageFiles, indexOfTitle: 0, progress: nil, fps: 30, saved: { b, s, error in
//
//         }, andFetched:{ b, lphoto, asset, error in
//
//            shareItem = lphoto
//
//            asyncSignal.end()
//        })
//        asyncSignal.waitUntilEnd()


        asyncSignal.begin()
        DispatchQueue.main.async {
            if let shareItems = shareItems, let rootViewController = UIApplication.shared.keyWindow?.rootViewController {

                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                    asyncSignal.end()
                }
                activityViewController.popoverPresentationController?.sourceView=rootViewController.view
                rootViewController.present(activityViewController, animated: true, completion: nil)

            }else{
                asyncSignal.end()
            }
        }
        asyncSignal.waitUntilEnd()


        return result
    }
}

extension Converter{
    fileprivate static let supportedWorkers:[ConverterWorker.Type] = [
        VideoConverter_Burst.self,
        VideoConverter_LivePhoto.self,
        VideoConverter_Gif.self,

        LivePhotoConverter_Burst.self,
        LivePhotoConverter_Gif.self,
        LivePhotoConverter_Video.self,

        GifConverter_Burst.self,
        GifConverter_LivePhoto.self,
        GifConverter_Timelapse.self,
        GifConverter_Video.self
    ]
}

private class ConverterTask: TaskPrototype, Taskable {
    public typealias ParamType = AppAsset
    public typealias ResultType = ConverterPHAssetResult

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){

        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }

    var converter:ConverterWorker? {
        let defaults = Converter.defaults as! ConverterAppDefaults
        let direction = defaults.convertingDirection

        let matchedWorkers = Converter.supportedWorkers.filter { $0.direction==direction }
        assert(matchedWorkers.count==1, "Duplicated converter worker direction found. \(matchedWorkers)")

        return type(of: matchedWorkers).init() as? ConverterWorker
    }

    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable) throws -> ConverterPHAssetResult?  {
        guard let converter = self.converter, converter.isSupported(asset: assetItem) else{
            throw TaskError.rejectedParam
        }

        let result = converter.convert(asset: assetItem, async)
        return result == nil ? nil : ConverterPHAssetResult(result: result)
    }
}

private struct ConverterCachedAsset {
    public var asset: PHAsset
    public var resultFileURL: URL

    static func cacheAsset(_ asset: PHAsset, image: UIImage, targetSize: CGSize) -> ConverterCachedAsset {
        let imageToWrite: UIImage
        if targetSize == image.size {
            imageToWrite = image
        }
        else {
            imageToWrite = UIGraphicsImageRenderer(size: targetSize, format: image.imageRendererFormat).imageWithCurrentContext { (cgContext) in
                UIColor.white.setFill()
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
                image.draw(in: AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: .zero, size: targetSize)))
            } ?? image
        }


        var data: Data?
        var fileExtension = "jpg"
        switch asset.uniformTypeIdentifier{
            case UTI.PNG:
                data = UIImagePNGRepresentation(imageToWrite)
                fileExtension = "png"
            default:
                data = UIImageJPEGRepresentation(imageToWrite, 1)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(Converter.info.identifier)_\(UUID().uuidString).\(fileExtension)")
        try? data?.write(to: url)

        return ConverterCachedAsset(asset: asset, resultFileURL: url)
    }
}

private struct ConverterPHAssetResult: TaskResultable{
    var result:Any?
}

fileprivate protocol ConverterWorker {

    init()

    static var direction:ConvertableDirection {get}

    func convert(asset:AppAsset, _ async: AsyncManualSignalable) -> Any?

    func isSupported(asset:AppAsset) -> Bool
}
/*
    VideoConverter
*/
fileprivate protocol VideoConverter: ConverterWorker{}

extension VideoConverter{
    fileprivate static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .video)
    }
}

fileprivate struct VideoConverter_Gif: VideoConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.gif, to:.video) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.uniformTypeIdentifier == UTI.GIF
    }
}

fileprivate struct VideoConverter_Burst: VideoConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.video) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .burst
    }
}

fileprivate struct VideoConverter_LivePhoto: VideoConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.video) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var exportedlivePhoto: PHLivePhoto?

        async.begin()

        let livePhotoOptions = PHLivePhotoRequestOptions()

        livePhotoOptions.deliveryMode = .highQualityFormat
        let req_livephoto = PHImageManager.default().requestLivePhoto(for: asset.asset
                , targetSize: .zero
                , contentMode: .default
                , options: livePhotoOptions
                , resultHandler: { livePhoto, info in

            exportedlivePhoto = livePhoto
            async.end()

        })
        asset.requestIDs.append(PHAssetRequestID(forImage: req_livephoto))
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
                let pairedVideoFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("pairedVideo.mov")
                try? videoData.write(to: pairedVideoFileURL, options: Data.WritingOptions.atomicWrite)

                resultURL = pairedVideoFileURL
            }
            async.end()
        }
        asset.requestIDs.append(PHAssetRequestID(forResourceData: req_data))
        async.waitUntilEnd()

        return resultURL
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .burst
    }
}

/*
    GifConverter
*/
fileprivate protocol GifConverter: ConverterWorker{}

extension GifConverter{
    fileprivate static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .gif)
    }
}

fileprivate struct GifConverter_Video: GifConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.video, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

fileprivate struct GifConverter_LivePhoto: GifConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.livephoto, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .livePhoto
    }
}

fileprivate struct GifConverter_Timelapse: GifConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.timelapse, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaSubtypes.contains(.videoTimelapse)
    }
}

fileprivate struct GifConverter_Burst: GifConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.gif) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.imageType == .burst
    }
}


/*
    LivePhotoConverter
*/

fileprivate protocol LivePhotoConverter: ConverterWorker{}
extension LivePhotoConverter{
    static var direction: ConvertableDirection {
        return ConvertableDirection(from: .any, to: .livephoto)
    }
}

fileprivate struct LivePhotoConverter_Gif: LivePhotoConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.gif, to:.livephoto) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {

        var paths:[String]?

        async.begin()
        PHImageManager.default().requestImageData(for: asset.asset, options: nil) { data, s, orientation, dictionary in
            if let data = data, let urls = data.extractAnimatedImageURLsAsGIF(){
                paths = urls.map { $0.path }
            }
            async.end()
        }
        async.waitUntilEnd()


        if let paths = paths{
            var result:PHLivePhoto?

            async.begin()
            LivePhotoWriter().createLivePhotoFromImages(paths: paths, indexOfTitle: 0, progress: nil, fps: 30) { photo in
                result = photo
                async.end()
            }
            async.waitUntilEnd()

            return result
        }

        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

fileprivate struct LivePhotoConverter_Burst: LivePhotoConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.burst, to:.livephoto) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

fileprivate struct LivePhotoConverter_Video: LivePhotoConverter {
    fileprivate static var direction: ConvertableDirection { return ConvertableDirection(from:.video, to:.livephoto) }

    init() {}

    func convert(asset: AppAsset, _ async: AsyncManualSignalable) -> Any? {
        return nil
    }

    func isSupported(asset: AppAsset) -> Bool {
        return asset.asset.mediaType == .video
    }
}

