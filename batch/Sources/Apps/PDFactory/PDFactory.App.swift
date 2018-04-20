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

//TODO: contribute into TPPDF
extension PDFPageFormat{

    var label:String{
        switch self {
            case .usHalfLetter, .usLetter, .usLegal, .usJuniorLegal, .usLedger:
                return usLabel
            case .ansiA, .ansiB, .ansiC, .ansiD, .ansiE:
                return ansiLabel
            case .a0, .a1, .a2, .a3, .a4, .a5, .a6, .a7, .a8, .a9, .a10:
                return aLabel
            case .b0, .b1, .b2, .b3, .b4, .b5, .b6, .b7, .b8, .b9, .b10:
                return bLabel
            case .c0, .c1, .c2, .c3, .c4, .c5, .c6, .c7, .c8, .c9, .c10:
                return cLabel
            }
    }

    var defaultLabel:String{
        return "\(self.layout.size.width)px x \(self.layout.size.height)px"
    }

    /**
    Returns the defined US paper label if this format is a US format.
    If it is not a US format, it will check other constants for correct size
    */
    var usLabel: String {
        switch self {
        case .usHalfLetter:
            return "US Half Letter"   // 140  x 216  mm | 5.5  x 8.5  in
        case .usLetter:
            return "US Letter"   // 216  x 279  mm | 8.5  x 11.0 in
        case .usLegal:
            return "US Legal"  // 216  x 356  mm | 8.5  x 14.0 in
        case .usJuniorLegal:
            return "US Junior Legal"   // 127  x 203  mm | 5.0  x 8.0  in
        case .usLedger:
            return "US Ledger"  // 279  x 432  mm | 11.0 x 17.0 in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined ANSI paper size if this format is a ANSI format.
     If it is not a ANSI format, it will check other constants for correct size
     */
    var ansiLabel: String {
        switch self {
        case .ansiA:
            return "ANSI A"   // 216  x 279  mm | 8.5  x 11.0 in
        case .ansiB:
            return "ANSI B" // 279  x 432  mm | 11.0 x 17.0 in
        case .ansiC:
            return "ANSI C" // 432  x 559  mm | 17.0 x 22.0 in
        case .ansiD:
            return "ANSI D" // 559  x 864  mm | 22.0 x 34.0 in
        case .ansiE:
            return "ANSI E" // 864  x 1118 mm | 34.0 x 44.0 in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined A-Series paper label if this format is a A-Series format.
     If it is not a A-Series format, it will check other constants for correct size
     */
    var aLabel: String {
        switch self {
        case .a0:
            return "A0" // 841  x 1189 mm | 33.1 x 46.8 in
        case .a1:
            return "A1" // 594  x 841  mm | 23.4 x 33.1 in
        case .a2:
            return "A2" // 420  x 594  mm | 16.5 x 23.4 in
        case .a3:
            return "A3"  // 297  x 420  mm | 11.7 x 16.5 in
        case .a4:
            return "A4"   // 210  x 297  mm | 8.3  x 11.7 in
        case .a5:
            return "A5"   // 148  x 210  mm | 5.8  x 8.3  in
        case .a6:
            return "A6"   // 105  x 148  mm | 4.1  x 5.8  in
        case .a7:
            return "A7"   // 74   x 105  mm | 2.9  x 4.1  in
        case .a8:
            return "A8"   // 52   x 74   mm | 2.0  x 2.9  in
        case .a9:
            return "A9"   // 37   x 52   mm | 1.5  x 2.0  in
        case .a10:
            return "A10"    // 26   x 37   mm | 1.0  x 1.5  in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined B-Series paper size if this format is a B-Series format.
     If it is not a B-Series format, it will check other constants for correct size
     */
    var bLabel: String {
        switch self {
        case .b0:
            return "B0" // 1000 x 1414 mm | 39.4 x 66.7 in
        case .b1:
            return "B1" // 707  x 1000 mm | 27.8 x 39.4 in
        case .b2:
            return "B2" // 500  x 707  mm | 19.7 x 27.8 in
        case .b3:
            return "B3" // 353  x 500  mm | 13.9 x 19.7 in
        case .b4:
            return "B4"  // 250  x 353  mm | 9.8  x 13.9 in
        case .b5:
            return "B5"   // 176  x 250  mm | 6.9  x 9.8  in
        case .b6:
            return "B6"   // 125  x 176  mm | 4.9  x 6.9  in
        case .b7:
            return "B7"   // 88   x 125  mm | 3.5  x 4.9  in
        case .b8:
            return "B8"   // 62   x 88   mm | 2.4  x 3.5  in
        case .b9:
            return "B9"   // 44   x 62   mm | 1.7  x 2.4  in
        case .b10:
            return "B10"    // 31   x 44   mm | 1.2  x 1.7  in
        default:
            return defaultLabel
        }
    }

    /**
     Returns the defined C-Series paper size if this format is a C-Series format.
     If it is not a C-Series format, it will check other constants for correct size
     */
    var cLabel: String {
        switch self {
        case .c0:
            return "C0" // 917  x 1297 mm | 36.1 x 51.5 in
        case .c1:
            return "C1" // 648  x 917  mm | 25.5 x 36.1 in
        case .c2:
            return "C2" // 458  x 648  mm | 18.0 x 25.5 in
        case .c3:
            return "C3"  // 324  x 458  mm | 12.8 x 18.0 in
        case .c4:
            return "C4"   // 229  x 324  mm | 9.0  x 12.8 in
        case .c5:
            return "C5"   // 162  x 229  mm | 6.4  x 9.0  in
        case .c6:
            return "C6"   // 114  x 162  mm | 4.5  x 6.4  in
        case .c7:
            return "C7"   // 81   x 114  mm | 3.2  x 4.5  in
        case .c8:
            return "C8"   // 57   x 81   mm | 2.2  x 3.2  in
        case .c9:
            return "C9"   // 40   x 57   mm | 1.6  x 2.2  in
        case .c10:
            return "C10"    // 28   x 40   mm | 1.1  x 1.6  in
        default:
            return defaultLabel
        }
    }
}

struct PDFactorySettings{
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
    ]
}

private protocol PDFactoryDefaults: AppDefaults{
    var formatLabel: String {get set}
}

extension Defaults: PDFactoryDefaults {
    fileprivate var formatLabel:String {
        set{ set(newValue) }
        get{ return get(or: PDFPageFormat.a4.label ) }
    }
}

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

    //TODO: Canvase Size
    //TODO: vertical horizontal
    //TODO: Aspectfit/fill
    //TODO: DPI
    //TODO: numbers of photos for each pages
    //TODO: caption enabled
    //TODO: thumbnail table sheet
    //TOOD: support 4x6 photos inch size

    public var controller: AppDockContent? {
        let items = PDFactorySettings.FormatPresets.map { (label, _) -> BAppUICollectionView.CollectionItem in
            return BAppUICollectionView.CollectionItem(title: label, image: nil, action: {

            })
        }
        let view = BAppUICollectionView(items:items)

        var p = AppDockContentPreferences()
        p.pinned = true
        p.minimumHeight = 100 // for test. remove this line after fixed app design
        return AppDockContentItem(view: view, preferences: p)
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

            let layout:PDFPageLayout
            if let defaults = PDFactory.defaults as? PDFactoryDefaults, let format = PDFactorySettings.FormatPresets[defaults.formatLabel] {
                layout = format.layout
            }else{
                layout = PDFPageFormat.a4.layout
            }

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


            let formatSize:CGSize
            if let defaults = PDFactory.defaults as? PDFactoryDefaults, let format = PDFactorySettings.FormatPresets[defaults.formatLabel] {
                formatSize = format.layout.size
            }else{
                formatSize = PDFPageFormat.a4.aSize
            }

            let imagePixelSize = formatSize.applying(CGAffineTransform(scaleX: 2, y: 2))
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

