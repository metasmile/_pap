//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import PDFGenerator
import UIKit

private struct PDFactoryPHAssetResult: TaskResultable{
    public var asset: PHAsset
    public var imageToRender: UIImage
}

public class PDFactory: App, PersistableApp, FinalizableApp, UIControllableApp, PhotoPickerViewControllerDisplayableApp, ItemCollectableApp {
    public static let taskType:Taskable.Type = _PDFactoryTask.self

    public static let paramType:TaskParamable.Type = AppAsset.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.pdfactory"
            , version: "0.1"
            , phase: .develop
            , appType: PDFactory.self
            , displayName: "PDFactory"
            , icon: nil
            , policy: AppPolicy.default
    )

    public required init() {}

    public var finalizingOptions: PHAssetFinalizingOptions{
        return [.delete]
    }

    public func titleWillBegin() -> String? {
        return "Starting to generate PDF...".localized
    }

    public func titleWillFinalize() -> String? {
        return "Generating PDF Pages...".localized
    }

    public func isItemEnables(for item: AppAsset) -> Bool {
        //for test
        return item.asset.mediaType == .image
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {

        let resultItems = result
                .filter { respondable in respondable.info.state == .completed }
                .flatMap { $0.result as? PDFactoryPHAssetResult }

        let rootViewController = UIApplication.shared.keyWindow?.rootViewController

        do {

            let page = resultItems.map { result -> PDFPage in
                return PDFPage.image(result.imageToRender)
            }

            let exportedDateFormat = DateFormatter()
            exportedDateFormat.dateFormat = "yyyyMMdd_HHmmss"

            let path = NSTemporaryDirectory().appending("exported_\(String(describing: type(of: self)))")
            try PDFGenerator.generate(page, to: path)

            if FileManager.default.fileExists(atPath: path) == false {
                throw "\(#function)_\(#file)"
            }

            asyncSignal.begin()
            DispatchQueue.main.async {
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [NSData(contentsOfFile: path)], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                    asyncSignal.end()
                }
                activityViewController.popoverPresentationController?.sourceView=rootViewController?.view
                rootViewController?.present(activityViewController, animated: true, completion: nil)
            }
            asyncSignal.stopUntilEnd()

        } catch let error {
            print(error)

            asyncSignal.begin()
            DispatchQueue.main.async {
                let alert = UIAlertController.init(title: type(of: self).info.displayName, message: "Sorry, something went wrong!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Confirm".localized, style: .default) { (alertAction) -> Void in
                    asyncSignal.end()
                })
                rootViewController?.present(alert, animated: true) {}
            }
            asyncSignal.stopUntilEnd()
        }

        return result
    }
}

private class _PDFactoryTask: TaskPrototype, Taskable {
    private var _pdfImageRequestOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        return options
    }

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        if let appAsset = param as? AppAsset{
            let asset = appAsset.asset

            //TODO: URL? to use low mem
            var renderImage:UIImage?

            async?.begin()

            let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: PDFPageSize.A4, contentMode: .default, options: _pdfImageRequestOptions) { (image, info) in
                renderImage = image
                async?.end()
            }
            appAsset.requestIDs += [PHAssetRequestID(forImage:imageRequestID)]

            async?.stopUntilEnd()

            if let image = renderImage{
                return PDFactoryPHAssetResult(asset: asset, imageToRender: image)
            }
        }
        return nil
    }
}

