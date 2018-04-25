//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import TPPDF
import UIKit

/*
TODO: UIActivity as a file
TODO: change 'imageToRender' as URL to prevent memory peaking
TODO: password input
TODO: Quality
FinalizableApp Common Share ActivityViewController
*/

import DefaultsKit

private struct PDFactoryPHAssetResult: TaskResultable{
    public var asset: PHAsset
    public var renderImageBoundSize: CGSize // maximum size of image + paper size
    public var renderImage: UIImage
    public var imageMetadata: [String: Any]?
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

    //TODO: Canvas Size
    //TODO: Portrait Landscape
    //TODO: Aspectfit/fill
    //TODO: DPI
    //TODO: numbers of photos for each pages
    //TODO: exif caption enabled

    // next
    //TODO: thumbnail table sheet
    //TOOD: support 4x6 ... photos inch size

    public lazy var controller: AppDockContent? = PDFactoryAppDockContent()

    public var finalizingOptions: [PHAssetFinalizingOption]{
        return [.custom]
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {

        let items = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { $0.result as? PDFactoryPHAssetResult }

        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else{
            return result
        }

        let defaults = PDFactory.defaults as? PDFactoryDefaults
        let imagesPerPage = defaults?.imagesPerPage ?? 1
        let imageQuality = defaults?.imageQuality ?? 1
        print(defaults, imagesPerPage)

        do {
            let document = PDFDocument(layout: PDFactory.defaultsPDFLayout)
            let container = PDFContainer.contentCenter

            for (i, item) in items.enumerated(){
                let pdfImage = PDFImage(image: item.renderImage, caption: nil, size: .zero, sizeFit: PDFImageSizeFit.widthHeight)
                document.addImage(container, image: pdfImage)
//                if i < items.count-1{
//                    document.createNewPage()
//                }
            }



//            for items in resultItems.chunked(into: imagesPerPage){
//                let container = PDFContainer.contentCenter

//                let table = PDFTable()
//
//                do {
//                    let style = PDFTableStyle()
//                    style.rowHeaderCount = 0
//                    style.columnHeaderCount = 0
//
//                    table.style = style
//
////                    try table.setCellStyle(row: 2, column: 2, style: nil)
//
//                    let tableData = items.chunked(into: 2).map { _items -> [UIImage] in
//                        return _items.map { _item -> UIImage in return _item.renderImage }
//                    }
//
//                    print(tableData)
//
//                    try table.generateCells(data: tableData, alignments: [
//                        [.center, .center],
//                        [.center, .center]
//                    ])
//                    document.addTable(container, table: table)
//
//                } catch PDFError.tableContentInvalid(let value) {
//                    // In case invalid input is provided, this error will be thrown.
//
//                    print("This type of object is not supported as table content: " + String(describing: (type(of: value))))
//                } catch {
//                    // General error handling in case something goes wrong.
//
//                    print("Error while creating table: " + error.localizedDescription)
//                }

//                for (i, item) in items.enumerated(){
//                    let sizefit:PDFImageSizeFit
//                    if item.renderImageBoundSize.height >= item.renderImageBoundSize.width{
//                        sizefit = PDFImageSizeFit.height
//                    }else{
//                        sizefit = PDFImageSizeFit.width
//                    }
//
//                    var avgLayoutConstant:CGFloat = 0
//                    for _item in items{
//                        if PDFImageSizeFit.width==sizefit{
//                            avgLayoutConstant += _item.renderImage.size.width
//                        }else if PDFImageSizeFit.height==sizefit{
//                            avgLayoutConstant += _item.renderImage.size.height
//                        }
//                    }
//
//                    let imageSize = CGSize(width: item.renderImage.size.width, height: avgLayoutConstant/CGFloat(items.count))
//
//                    let pdfImage = PDFImage(image: item.renderImage, caption: nil, size: imageSize, sizeFit: PDFImageSizeFit.height)
//                    pdfImage.quality = CGFloat(imageQuality)
//                    document.addImage(container, image: pdfImage)
//                }
//
//
//                document.createNewPage()
//            }

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
            //read image
            var renderImage:UIImage?

            async?.begin()
            let imageMaxSize:CGSize = PDFactory.defaultsPDFLayout.size
            let imagePixelSize = imageMaxSize.applying(CGAffineTransform(scaleX: 2, y: 2))
            let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: imagePixelSize, contentMode: .aspectFit, options: _pdfImageRequestOptions) { (image, info) in
                renderImage = image
                async?.end()
            }

            appAsset.requestIDs += [PHAssetRequestID(forImage:imageRequestID)]
            async?.waitUntilEnd()

            //read metadata
            var imageMetadata: [String: Any]?
            async?.begin()

            let option = PHContentEditingInputRequestOptions()
            option.isNetworkAccessAllowed = true
            option.canHandleAdjustmentData = { _ -> Bool in
                return true
            }
            let editingInputId = appAsset.requestContentEditing(options: option) { item in
                assert(item?.input.fullSizeImageURL != nil, "item.input.fullSizeImageURL is nil")
                if let item = item, let url = item.input.fullSizeImageURL {
                    let data = try! Data(contentsOf: url)
                    imageMetadata = data.getMetadata()
                }
                async?.end()
            }
            appAsset.requestIDs += [PHAssetRequestID(forEditingInput: editingInputId)]
            async?.waitUntilEnd()

            if let image = renderImage{
                return PDFactoryPHAssetResult(asset: asset, renderImageBoundSize: imagePixelSize, renderImage:image, imageMetadata:imageMetadata)
            }
        }
        return nil
    }
}

