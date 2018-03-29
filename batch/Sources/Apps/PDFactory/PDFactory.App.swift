//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import PDFGenerator
import UIKit

/*
TODO: UIActivity as a file
TODO: change 'imageToRender' as URL to prevent memory peaking
TODO: password input
TODO: Quality
FinalizableApp Common Share ActivityViewController
*/

private struct PDFactoryPHAssetResult: TaskResultable{
    public var asset: PHAsset
    public var imageToRender: UIImage
}

public class PDFactory: App, PersistableApp, FinalizableApp, PhotoPickerViewControllerDisplayableApp, PhotoPickerCollectionViewDisplayableApp {
    public static let taskType:Taskable.Type = _PDFactoryTask.self

    public static let paramType:TaskParamable.Type = AppAsset.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.pdfactory"
            , version: "1.0"
            , phase: .beta
            , appType: PDFactory.self
            , displayName: "PDFactory"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
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

    public lazy var numberOfItemsShouldSelect: Int? = 3 //for test

    public func isItemEnables(for item: AppAsset) -> Bool {
        //for test
        return item.asset.mediaType == .image
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {

        let resultItems = result
                .filter { respondable in respondable.info.state == .completed }
                .flatMap { $0.result as? PDFactoryPHAssetResult }

        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else{
            return result
        }

        do {

            let page = resultItems.map { result -> PDFPage in
                return PDFPage.image(result.imageToRender)
            }

            let path = NSTemporaryDirectory().appending("exported_\(String(describing: type(of: self)))")
            try PDFGenerator.generate(page, to: path)

            if FileManager.default.fileExists(atPath: path) == false {
                throw "\(#function)_\(#file)"
            }

            guard let data = NSData(contentsOfFile: path) else {
                throw "\(#function)_\(#file)"
            }

            asyncSignal.begin()
            DispatchQueue.main.async {

                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                    asyncSignal.end()
                }
                activityViewController.popoverPresentationController?.sourceView=rootViewController.view
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }

            asyncSignal.stopUntilEnd()

        } catch _ {

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert("Sorry, something went wrong.".localized, title:type(of: self).info.displayName) { alertAction in
                    DispatchQueue.global().async{ asyncSignal.end() }
                }
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

