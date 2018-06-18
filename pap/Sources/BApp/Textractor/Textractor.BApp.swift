//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision

public class Textractor: BApp, PHAssetFinalizableApp, AppDockApp, PhotoPickerViewControllerDelegatableApp {
    public static let taskType:Taskable.Type = _TextractorTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.textractor"
            , version: "0.1"
            , phase: .develop
            , appType: Textractor.self
            , displayName: "Textractor", description:nil, keywords:nil
            , iconBundleName: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public required init() {}

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    //TODO: remove this block
    public func shouldFinalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> Bool {
        return false
    }
    //TODO: remove this block

    public var titleWillFinalize: String? {
        return "Recognizing Text in Photos...".localized
    }
    public var doneButtonTitle: String? {
        return "Extract".localized
    }


    fileprivate var textDetector = Vision().textDetector()
    fileprivate var cloudTextDetector = Vision().cloudTextDetector()
}

private class _TextractorTask: TaskPrototype, Taskable {

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        if let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset, let image = asset.asUIImage{
            let result = runTextRecognition(with: image, async)
            processResult(from:result, async)

//            let result = runCloudTextRecognition(with: image, async)
//            processCloudResult(from: result, async)

            return PHAssetResultItem(asset: asset, contentEditingOutput: nil)
        }
        return nil
    }

    func runTextRecognition(with image: UIImage,_ async: AsyncManualSignalable) -> [VisionText]? {
        let visionImage = VisionImage(image: image)
        let textDetector = AppCenter.default.currentInstanceAs(Textractor.self)?.textDetector

        var result:[VisionText]?

        async.begin()
        textDetector?.detect(in: visionImage) { features, error in
            if let error = error {
                print("Received error: \(error)")
            }
            result = features
            async.end()
        }
        async.waitUntilEnd()
        return result
    }

    func runCloudTextRecognition(with image: UIImage,_ async: AsyncManualSignalable) -> VisionCloudText? {
        let visionImage = VisionImage(image: image)
        let cloudTextDetector = AppCenter.default.currentInstanceAs(Textractor.self)?.cloudTextDetector

        var result:VisionCloudText?

        async.begin()
        cloudTextDetector?.detect(in: visionImage) { features, error in
            if let error = error {
                print("Received error: \(error)")
            }
            result = features
            async.end()
        }
        async.waitUntilEnd()
        return result
    }

    func processResult(from text: [VisionText]?, _ async: AsyncManualSignalable?=nil) {
        guard let features = text else {
            return
        }

        var testResults:String = ""

        for text in features {
            if let block = text as? VisionTextBlock {
                for line in block.lines {
                    for element in line.elements {
                        testResults += element.text + "|"
                    }
                }
            }
        }

        async?.begin()
        DispatchQueue.main.async {
            UIAlertController.alert(testResults != "" ? testResults : "Not found any text", completion:{ _ in
                async?.end()
            })
        }
        async?.waitUntilEnd()
    }

    func processCloudResult(from text: VisionCloudText?, _ async: AsyncManualSignalable?=nil) {
        guard let features = text, let pages = features.pages else {
            return
        }

        var testResults:String = ""

        for page in pages {
            for block in page.blocks ?? []  {
                for paragraph in block.paragraphs ?? [] {
                    for word in paragraph.words ?? [] {
                        if let symbols = word.symbols{
                            for symbol in symbols {
                                testResults += symbol.text ?? "" + "|"
                            }
                        }
                    }
                }
            }
        }
        async?.begin()
        DispatchQueue.main.async {
            UIAlertController.alert(testResults != "" ? testResults : "Not found any text", completion:{ _ in
                async?.end()
            })
        }
        async?.waitUntilEnd()
    }

    func detectorOrientation(in image: UIImage) -> VisionDetectorImageOrientation {
        switch image.imageOrientation {
        case .up:
            return .topLeft
        case .down:
            return .bottomRight
        case .left:
            return .leftBottom
        case .right:
            return .rightTop
        case .upMirrored:
            return .topRight
        case .downMirrored:
            return .bottomLeft
        case .leftMirrored:
            return .leftTop
        case .rightMirrored:
            return .rightBottom
        }
    }
}

