//
// Created by BLACKGENE on 02/05/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

//INFO: mainly focusing on GIF, at first.

import Foundation
import UIKit
import MobileCoreServices
import Photos

public class ConvertAppConfigValue: NSObject, KeyPathWatchable, AppConfigValuable {
    @objc dynamic
    public var convertingDirectionIdentifier:String = ConvertApp.defaultWorker.direction.identifier
}

public class ConvertApp: BApp,
        AppDockControllableApp,
        ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp,
        PhotoPickerCollectionViewDisplayableApp,
        PhotoPickerViewControllerDelegatableApp {

    public static let taskType:Taskable.Type = ConvertAppTask.self
    public static let paramType:TaskParamable.Type = AppAsset.self

    public static var configure:(() -> ConvertAppConfigValue)?

    @objc dynamic
    public private(set) lazy var config: ConvertAppConfigValue? = ConvertAppConfigValue()

    public private(set) var dockContent: AppDockContent?

    public static let info = AppInfo(
            identifier: "com.stells.batch.converter"
            , version: "1.0"
            , phase: .develop
            , appType: ConvertApp.self
            , displayName: "Convert" // 1 - 1
            , icon: R.image.photosFilterAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public init() {
        dockContent = ConvertAppDockContent(app:self)
    }

    public var doneButtonTitle: String? {
        return "Convert".localized
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return currentWorker?.shouldSelect(source: item) ?? true
    }

    public var numberOfItemsShouldSelect: Int? {
        return currentWorker?.numberOfItemsShouldSelect ?? nil
    }

    public var finalizingPresets: [PHAssetFinalizingPresets]? {
        return nil
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){

    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultItems = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { ($0.result as? ConvertAppResult)?.result }

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

extension ConvertApp{
    var defaults:ConvertAppDefaults{
        return ConvertApp.defaults as! ConvertAppDefaults
    }

    var currentWorker:Converter.Type?{
        return ConvertApp.supportedWorkers.first { converterType in
            return converterType.direction==defaults.convertingDirection
        }
    }

    static let supportedWorkers:[Converter.Type] = [
        MovConverter_Burst.self,
        MovConverter_LivePhoto.self,
        MovConverter_Gif.self,

        LivePhotoConverter_Burst.self,
        LivePhotoConverter_Gif.self,
        LivePhotoConverter_Video.self,

        GifConverter_Burst.self,
        GifConverter_LivePhoto.self,
        GifConverter_Timelapse.self,
        GifConverter_Mov.self
    ]

    static var defaultWorker:Converter.Type{
        return GifConverter_LivePhoto.self
    }
}


private struct ConvertAppResult: TaskResultable{
    var result:Any?
}

private class ConvertAppTask: TaskPrototype, Taskable {
    public typealias ParamType = AppAsset
    public typealias ResultType = ConvertAppResult

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){

        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }

    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable) throws -> ConvertAppResult?  {
        let defaults = ConvertApp.defaults as! ConvertAppDefaults
        let direction = defaults.convertingDirection

        let needsConverter = ConverterSpec.acquireInstance(collection: ConvertApp.supportedWorkers, direction: direction, asset: assetItem)

        guard let converter = needsConverter else {
            throw TaskError.rejectedParam
        }

        let result = converter.convert(source: assetItem, async)
        return result == nil ? nil : ConvertAppResult(result: result)
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
            case UTCoreTypes.PNG:
                data = UIImagePNGRepresentation(imageToWrite)
                fileExtension = "png"
            default:
                data = UIImageJPEGRepresentation(imageToWrite, 1)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(ConvertApp.info.identifier)_\(UUID().uuidString).\(fileExtension)")
        try? data?.write(to: url)

        return ConverterCachedAsset(asset: asset, resultFileURL: url)
    }
}
