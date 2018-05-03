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
//    public private(set) lazy var controller: AppDockContent? = GIFMakerAppDockContent()
    public private(set) var controller: AppDockContent?

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
        return true
    }

    public var numberOfItemsShouldSelect: Int? {
        return nil
    }

    public var finalizingPresets: [PHAssetFinalizingPresets]? {
        return nil
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){

    }

    public func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool {
        return true
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let resultItems = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { ($0.result as? ConverterPHAssetResult)?.items }.reduce([], +)

        let imageFiles = resultItems.map({ $0.imageFileURL.path })

        var shareItem:Any?

//        asyncSignal.begin()
//        let builder = TimeLapsBuilder(imagePaths: imageFiles)
//        builder.build({ progress in  }, success: { url in
//            data = url
//
//            asyncSignal.end()
//
//        }, failure: { error in
//            print(error)
//            asyncSignal.end()
//        })
//        asyncSignal.waitUntilEnd()


        asyncSignal.begin()
        let lpWriter = LivePhotoWriter()

        lpWriter.saveLivePhotoFromImages(paths: imageFiles, indexOfTitle: 0, progress: nil, fps: 30, saved: { b, s, error in

         }, andFetched:{ b, lphoto, asset, error in

            shareItem = lphoto

            asyncSignal.end()
        })
        asyncSignal.waitUntilEnd()


        asyncSignal.begin()
        DispatchQueue.main.async {
            if let shareItem = shareItem, let rootViewController = UIApplication.shared.keyWindow?.rootViewController {

                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [shareItem], applicationActivities: nil)
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


private class ConverterTask: TaskPrototype, Taskable {
    public typealias ParamType = AppAsset
    public typealias ResultType = ConverterPHAssetResult

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){

        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        guard let appAsset = param as? AppAsset else { return nil }
        return try _perform(appAsset, async)
    }

    private func _perform(_ assetItem: AppAsset, _ async: AsyncManualSignalable?) throws -> ConverterPHAssetResult?  {
        var result: ConverterPHAssetResult?

        let targetSize = GIFMakerSettings.size.sizeWithAspectRatio()
        let contentMode = PHImageContentMode.aspectFit//PHImageContentMode(rawValue: (GIFMaker.defaults as! GIFMakerDefaults).contentMode) ?? PHImageContentMode.aspectFit

        async?.begin()

        if assetItem.asset.mediaType == .video {
            async?.end()
        }
        else if assetItem.asset.imageType == .stillImage {
            let response = assetItem.asset.requestImage(targetSize: targetSize, contentMode: contentMode)

            if let image = response.1, let uti = assetItem.asset.uniformTypeIdentifier {
                result = ConverterPHAssetResult(items: [ConverterCachedAsset.cacheAsset(assetItem.asset, image: image, targetSize: targetSize, uti: uti)])
                assetItem.requestIDs += [PHAssetRequestID(forImage:response.0)]
            }

            async?.end()
        }
        else if assetItem.asset.imageType == .burst {
            var results = [ConverterCachedAsset]()

            let fetchOptions = PHFetchOptions()
            fetchOptions.includeAllBurstAssets = true

            let fetchedAsset = PHAsset.fetchAssets(withBurstIdentifier: assetItem.asset.burstIdentifier ?? "", options: fetchOptions)
            fetchedAsset.enumerateObjects { (asset, idx, stop) in
                let response = asset.requestImage(targetSize: targetSize, contentMode: contentMode)

                if let image = response.1, let uti = assetItem.asset.uniformTypeIdentifier {
                    results.append(ConverterCachedAsset.cacheAsset(assetItem.asset, image: image, targetSize: targetSize, uti: uti))
                    assetItem.requestIDs += [PHAssetRequestID(forImage:response.0)]
                }
            }

            result = ConverterPHAssetResult(items: results)

            async?.end()
        }
        else if assetItem.asset.imageType == .livePhoto {
            async?.end()
        }

        async?.waitUntilEnd()
        return result
    }
}


private struct ConverterCachedAsset {
    public var asset: PHAsset
    public var imageFileURL: URL

    static func cacheAsset(_ asset: PHAsset, image: UIImage, targetSize: CGSize, uti: String) -> ConverterCachedAsset {
        let imageToWrite: UIImage
        if targetSize == image.size {
            imageToWrite = image
        }
        else {
            imageToWrite = UIGraphicsImageRenderer(size: targetSize, format: image.imageRendererFormat).imageWithCurrentContext { (cgContext) in
                UIColor.white.setFill()
                cgContext.fill(CGRect(origin: .zero, size: targetSize))
                image.draw(at: CGPoint(x: (targetSize.width - image.size.width) / 2, y: (targetSize.height - image.size.height) / 2))
            } ?? image
        }

        var data: Data?
        var fileExtension = "jpg"
        switch uti as CFString {
        case kUTTypePNG:
            data = UIImagePNGRepresentation(imageToWrite)
            fileExtension = "png"
        default:
            data = UIImageJPEGRepresentation(imageToWrite, 1)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(Converter.info.identifier)_\(UUID().uuidString).\(fileExtension)")
        try? data?.write(to: url)

        return ConverterCachedAsset(asset: asset, imageFileURL: url)
    }
}

private struct ConverterPHAssetResult: TaskResultable{
    public var items: [ConverterCachedAsset]
}