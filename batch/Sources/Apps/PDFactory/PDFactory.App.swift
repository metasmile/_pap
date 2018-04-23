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

import DefaultsKit

private enum PDFDocumentDPI{
    case dpi72
    case dpi300
}

struct PDFactorySettings{
    static let FormatPresetFitToPhotoSize = "Fit To Photo Size"

    static let FormatPresets:[String:PDFPageFormat] = [
        PDFPageFormat.a3.label: PDFPageFormat.a3
        , PDFPageFormat.a4.label: PDFPageFormat.a4
        , PDFPageFormat.a5.label: PDFPageFormat.a5
        , PDFPageFormat.a6.label: PDFPageFormat.a6

        , PDFPageFormat.b3.label: PDFPageFormat.b3
        , PDFPageFormat.b4.label: PDFPageFormat.b4

        , PDFPageFormat.b5.label: PDFPageFormat.b5
        , PDFPageFormat.c5.label: PDFPageFormat.c5

        , PDFPageFormat.usLegal.label: PDFPageFormat.usLegal
        , PDFPageFormat.usLetter.label: PDFPageFormat.usLetter
        , PDFPageFormat.usHalfLetter.label: PDFPageFormat.usHalfLetter
        , PDFPageFormat.usLedger.label: PDFPageFormat.usLedger

        , FormatPresetFitToPhotoSize : PDFPageFormat.a4
    ]
}

private protocol PDFactoryDefaults: AppDefaults{
    var formatPreset: String {get set}
    var landscape: Bool {get set}
    var copiesPerPage: UInt {get set}
}

extension Defaults: PDFactoryDefaults {
    fileprivate var formatPreset:String {
        set{ set(newValue) }
        get{ return get(or: PDFPageFormat.a4.label ) }
    }

    fileprivate var landscape:Bool {
        set{ set(newValue) }
        get{ return get(or: false ) }
    }

    fileprivate var copiesPerPage:UInt {
        set{ set(newValue) }
        get{ return get(or: 1 ) }
    }
}

private struct PDFactoryPHAssetResult: TaskResultable{
    public var asset: PHAsset
    public var renderPixelSize: CGSize
    public var renderImage: UIImage
}

extension PDFactory{
    fileprivate class var defaultsPDFFormat:PDFPageFormat{
        if let defaults = PDFactory.defaults as? PDFactoryDefaults
        , let format = PDFactorySettings.FormatPresets[defaults.formatPreset] {
            return format
        }else{
            return PDFPageFormat.a4
        }
    }

    fileprivate class var defaultsPDFLayout:PDFPageLayout{
        var defaultLayout:PDFPageLayout = defaultsPDFFormat.layout
        if let defaults = PDFactory.defaults as? PDFactoryDefaults, defaults.landscape {
            defaultLayout.size = CGSize(width: defaultLayout.size.height, height: defaultLayout.size.width)
        }
        return defaultLayout
    }
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
//    public var controller: AppDockContent? {
//        let items = PDFactorySettings.FormatPresets.map { (label, _) -> BAppUICollectionView.CollectionItem in
//            return BAppUICollectionView.CollectionItem(title: label, image: nil, action: {
//
//            })
//        }
//        let view = BAppUICollectionView(items:items)
//
//        var p = AppDockContentPreferences()
//        p.pinned = true
//        p.minimumHeight = 100 // for test. remove this line after fixed app design
//        return AppDockContentItem(view: view, preferences: p)
//    }

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
            let document = PDFDocument(layout: PDFactory.defaultsPDFLayout)

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

            let imageMaxSize:CGSize = PDFactory.defaultsPDFLayout.size
            let imagePixelSize = imageMaxSize.applying(CGAffineTransform(scaleX: 2, y: 2))
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

