//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import TPPDF // https://github.com/Techprimate/TPPDF 👍
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
    public var renderPixelSize: CGSize
    public var renderImage: UIImage
}

public class PDFactory: BatchApp, FinalizableApp, PhotoPickerViewControllerDelegatableApp,
        PhotoPickerCollectionViewDisplayableApp , AppDockControllableApp{

    public static let taskType:Taskable.Type = _PDFactoryTask.self

    public static let paramType:TaskParamable.Type = AppAsset.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.pdfactory"
            , version: "1.0"
            , phase: .beta
            , appType: PDFactory.self
            , displayName: "PDFactory"
            , icon: R.image.pdFactoryAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public required init() {}

    public var doneButtonTitle: String?{
        return "Create %@".localizedFormatted("PDF")
    }

    public var titleWillBegin:String{
        return "Starting to create PDF...".localized
    }

    public var titleWillFinalize:String{
        return "Creating PDF Pages...".localized
    }

    public lazy var numberOfItemsShouldSelect: Int? = 20 //for test

    public func shouldSelect(item: AppAsset) -> Bool {
        //for test
        return item.asset.mediaType == .image
    }

    public var finalizingOptions: [PHAssetFinalizingOption]{
        return [.custom]
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {

        let resultItems = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { $0.result as? PDFactoryPHAssetResult }

        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else{
            return result
        }

        do {
            let layout = PDFPageFormat.a4.layout
            let document = PDFDocument(layout: layout)

            for (i, item) in resultItems.enumerated(){
                let pdfImage = PDFImage(image: item.renderImage, caption: nil, size: .zero, sizeFit: PDFImageSizeFit.widthHeight)
                document.addImage(image: pdfImage)

                if i < resultItems.count-1{
                    document.createNewPage()
                }
            }

            /*
            let images = [
                PDFImage(image: UIImage(named: "Image-1.jpg")!,
                         caption: PDFAttributedText(text: NSAttributedString(string: "In this picture you can see a beautiful waterfall!", attributes: captionAttributes))),
                PDFImage(image: UIImage(named: "Image-2.jpg")!,
                         caption: PDFAttributedText(text: NSAttributedString(string: "Forrest", attributes: captionAttributes))),
            ]

            document.addImagesInRow(images: images, spacing: 10)

            list.addItem(PDFListItem(symbol: .numbered(value: nil))
            .addItem(PDFListItem(content: "Introduction")
                .addItem(PDFListItem(symbol: .numbered(value: nil))
                    .addItem(PDFListItem(content: "Text"))
                    .addItem(PDFListItem(content: "Attributed Text"))
                ))
            .addItem(PDFListItem(content: "Usage")))
            */

            let pdfURL = try PDFGenerator.generateURL(document: document, filename: "exported_\(String(describing: type(of: self))).pdf")

            if FileManager.default.fileExists(atPath: pdfURL.path) == false {
                throw "\(#function)_\(#file)"
            }

            guard let pdfData = try? Data(contentsOf: pdfURL) else {
                throw "\(#function)_\(#file)"
            }

            asyncSignal.begin()
            DispatchQueue.main.async {
                let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                    asyncSignal.end()
                }
                activityViewController.popoverPresentationController?.sourceView=rootViewController.view
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }

            asyncSignal.waitUntilEnd()

        } catch _ {

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert("Sorry, something went wrong.".localized, title:type(of: self).info.displayName) { alertAction in
                    DispatchQueue.global().async{ asyncSignal.end() }
                }
            }
            asyncSignal.waitUntilEnd()
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

            let imagePixelSize = PDFPageFormat.a4.ansiSize.applying(CGAffineTransform(scaleX: 2, y: 2))
            let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: imagePixelSize, contentMode: .aspectFit, options: _pdfImageRequestOptions) { (image, info) in
                renderImage = image
                async?.end()
            }
            appAsset.requestIDs += [PHAssetRequestID(forImage:imageRequestID)]

            async?.waitUntilEnd()

            if let image = renderImage{
                return PDFactoryPHAssetResult(asset: asset, renderPixelSize: imagePixelSize, renderImage:image)
            }
        }
        return nil
    }
}

