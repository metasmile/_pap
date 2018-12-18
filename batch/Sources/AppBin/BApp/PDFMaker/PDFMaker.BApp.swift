//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import TPPDF
import UIKit
import PropertyKit

private struct PDFMakerAppPHAssetResult: AppTaskResultable {
    public var asset: PHAsset
    public var renderImageBoundSize: CGSize // maximum size of image + paper size
    public var renderImage: UIImage
    public var imageMetadata: [String: Any]?
}

public class PDFMakerApp: BApp, FinalizableApp, PhotoPickerViewControllerAppearanceDelegatableApp,
        PhotoPickerCollectionViewDelegatableApp , AppDockApp {

    public static let taskType: AppTaskable.Type = _PDFMakerAppTask.self

    public static let paramType: AppTaskParamable.Type = AppAsset.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.pdfmaker"
            , version: "1.0"
            , phase: .release
            , appType: PDFMakerApp.self
            , displayName: "PDF Maker"
            , description:"PDFMaker makes PDF document from multiple images with various page options.".localized
            , keywords:["PDF","PDF Builder","Documents","PDF Editor","Margin","Layout","Pages"]
            , iconBundleName: R.image.pdfMakerBAppIcon.name
            , themeColor: .red, policy: AppPolicy.default
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

    public lazy var numberOfItemsShouldSelect: Int? = 100

    public func shouldSelect(item: AppAsset) -> Bool {
        //for test
        return item.asset.mediaType == .image
    }

    public lazy var content: AppDockContent? = PDFMakerAppAppDockContent()

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {

        let items = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { $0.result as? PDFMakerAppPHAssetResult }

        guard let _ = UIViewController.presentable else{
            return result
        }

        let defaults = PDFMakerApp.defaults as! PDFMakerAppDefaults
//        let imagesPerPage = defaults.imagesPerPage

        do {
            let document = PDFDocument(layout: PDFMakerApp.defaultsPDFLayout)
            let isLandspace = document.layout.size.width > document.layout.size.height
            let container = PDFContainer.contentCenter

            for (i, item) in items.enumerated(){

                //metadata
                var caption:PDFText?
                if item.imageMetadata != nil && defaults.metadataCaption {
                    document.setFont(font: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize/6))
                    caption = PDFSimpleText(text: String(describing: item.imageMetadata))
                }

                //scale mode
                var sizeFitMode = PDFImageSizeFit.widthHeight
                let fillPageMode = defaults.scaleMode == PDFMakerAppSettings.ScaleMode.fillPage.rawValue
                if fillPageMode{
                    let isImageLandspace = item.renderImage.size.width > item.renderImage.size.height

                    if isLandspace {
                        if isImageLandspace {
                            sizeFitMode = PDFImageSizeFit.width
                        }else{
                            sizeFitMode = PDFImageSizeFit.height
                        }
                    }else{
                        if isImageLandspace {
                            sizeFitMode = PDFImageSizeFit.height
                        }else{
                            sizeFitMode = PDFImageSizeFit.width
                        }
                    }
                }

                let pdfImage = PDFImage(image: item.renderImage, caption: caption, size: item.renderImage.size, sizeFit: sizeFitMode)
                //quality
                pdfImage.quality = CGFloat(defaults.imageQuality)

                document.addImage(container, image: pdfImage)

                if i < items.count-1, fillPageMode == false{
                    document.createNewPage()
                }
            }

            let pdfURL = try PDFGenerator.generateURL(document: document, filename: "exported_\(String(describing: type(of: self))).pdf")

            if FileManager.default.fileExists(atPath: pdfURL.path) == false {
                throw "\(#function)_\(fileName())"
            }

            guard let pdfData = try? Data(contentsOf: pdfURL) else {
                throw "\(#function)_\(fileName())"
            }

            asyncSignal.begin()

            UIActivityViewController.share(activityItems: [pdfData]) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
                asyncSignal.end()
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

private class _PDFMakerAppTask: AppTaskPrototype, AppTaskable {

    private var _pdfImageRequestOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        return options
    }

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        (param as? AppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        if let appAsset = param as? AppAsset{
            let asset = appAsset.asset

            //TODO: URL? to use low mem
            //read image
            var renderImage:UIImage?

            async.begin()
            let imageMaxSize:CGSize = PDFMakerApp.defaultsPDFLayout.size
            let imagePixelSize = imageMaxSize.applying(CGAffineTransform(scaleX: 2, y: 2))
            let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: imagePixelSize, contentMode: .aspectFit, options: _pdfImageRequestOptions) { (image, info) in
                renderImage = image
                async.end()
            }

            appAsset.appendRequestId(PHAssetRequestID(forImage:imageRequestID))
            async.waitUntilEnd()

            //read metadata
            var imageMetadata: [String: Any]?

            if (PDFMakerApp.defaults as! PDFMakerAppDefaults).metadataCaption{
                async.begin()

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
                    async.end()
                }
                appAsset.appendRequestId(PHAssetRequestID(forEditingInput: editingInputId))
                async.waitUntilEnd()
            }

            if let image = renderImage{
                return PDFMakerAppPHAssetResult(asset: asset, renderImageBoundSize: imagePixelSize, renderImage:image, imageMetadata:imageMetadata)
            }
        }
        return nil
    }
}

import Intents

extension PDFMakerApp:UIApplicationDelegateLaunchableApp{
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenIntent()
            openAppIntent.appId = PDFMakerApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: PDFMakerApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open PDF Maker.".localized.localized
            return [openAppIntent]
        } else {
            return []
        }
    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }
}
