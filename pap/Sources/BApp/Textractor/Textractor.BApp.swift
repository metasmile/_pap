//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision
import DefaultsKit

//TODO: Memo/Keep/Notes lineup

private typealias TextractorParam = PHAssetItem<ImageEditStateValue>
private struct TextractorResult: TaskResultable{
    fileprivate let asset:PHAsset
    fileprivate let text:String
}

private protocol TextractorDefaults: AppDefaults{
    var autoSelect: Bool {get set}
}

extension Defaults: TextractorDefaults {
    fileprivate var autoSelect: Bool {
        set{ set(newValue) }
        get{ return get(or: false) }
    }
}


public class Textractor: NSObject, KeyPathWatchable, BApp
        , FinalizableApp
        , AppDockApp
        , PhotoPickerViewControllerDelegatableApp
        , PhotoPickerCollectionViewAsyncAutoDisplayableApp {

    public static let taskType:Taskable.Type = _TextractorTask.self

    public static let paramType:TaskParamable.Type = PHAssetItem<ImageEditStateValue>.self

    public private(set) lazy var dockContent: AppDockContent? = TextractorDockContent()

    private let appDefaults = Textractor.defaults as! TextractorDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = appDefaults.autoSelect
    
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

    public required override init() {}

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let items = result
                .filter { respondable in respondable.info.state == .completed }
                .compactMap { ($0.result as? TextractorResult)?.text }


        asyncSignal.begin()
        DispatchQueue.main.async{
            UIActivityViewController.presentAsDefault(activityItems: items, excludedActivityTypes: nil) { type, b, anies, error in
                asyncSignal.end()
            }
        }

        asyncSignal.waitUntilEnd()

        return result
    }

    public func shouldAutoSelectAsynchronously(item: AppAsset, _ async: AsyncSignal) -> PhotoPickerCollectionViewAsyncSelection {
        if appDefaults.autoSelect == false{
            return .none
        }

        var foundText = false

        async.begin()

        if let image = item.asset.asUIImage{
            let visionImage = VisionImage(image: image)
            let textDetector = self.textDetector

            var result:[VisionText]?

            textDetector.detect(in: visionImage) { features, error in
                if let error = error {
                    print("Received error: \(error)")
                }

                //TODO: store result text by id
                result = features

                var testResults:String = ""
                if let features = features{
                    for text in features {
                        if let block = text as? VisionTextBlock {
                            for line in block.lines {
                                for element in line.elements {
                                    testResults += element.text + " "
                                }
                            }
                        }
                    }
                }

                foundText = testResults.count > 0
                print("testResults", testResults.count)

                async.end()
            }
        }else{
            async.end()
        }

        async.waitUntilEnd()

        return foundText ? .visible : .none
    }

    public var titleWillFinalize: String? {
        return "Saving Texts ...".localized
    }

    public func titleDidUpdate(progress: Float) -> String? {
        return "Recognizing ... %@ ".localizedFormatted("\(Int(progress * 100))%")
    }

    public var doneButtonTitle: String? {
        return "Grab".localized
    }

    fileprivate var textDetector = Vision().textDetector()
    fileprivate var cloudTextDetector = Vision().cloudTextDetector()
}

private class _TextractorTask: TaskPrototype, Taskable {

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        if let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset, let image = asset.asUIImage{
            let result = runTextRecognition(with: image, async)

            if let text = processResult(from:result, async){

//                let url = FileURL.temp(UUID().uuidString + ".txt", UTI.utf8PlainText, group:FileURL.fileAndQueuePrivateGroup())
//
//                print(text)
//
//                print(url.path)
//
//                try? text.write(to: url, atomically: true, encoding: .utf8)

                return TextractorResult(asset: asset, text: text)
            }
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

    func processResult(from text: [VisionText]?, _ async: AsyncManualSignalable?=nil) -> String? {
        guard let features = text else {
            return nil
        }

        var testResults:String = ""

        for text in features {
            if let block = text as? VisionTextBlock {
                for line in block.lines {
                    for element in line.elements {
                        testResults += element.text + " "
                    }
                }
            }
        }

        //INFO: DEBUG

//        async?.begin()
//        DispatchQueue.main.async {
//            UIAlertController.alert(testResults != "" ? testResults : "Not found any text", completion:{ _ in
//                async?.end()
//            })
//        }
//        async?.waitUntilEnd()

        return testResults
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


fileprivate class TextractorDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = Textractor.defaults as! TextractorDefaults

    private let primaryColor = UIColor(red:0.6, green:0.6, blue:0.6, alpha:1)

    lazy var view: UIView = UITableView()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = (view as! UITableView).rowHeight * CGFloat(1)
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {
        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 52
            view.allowsSelection = false
            view.register(Cell.self, forCellReuseIdentifier: Textractor.info.identifier)
//            view.backgroundColor = UIColor(red: 31 / 255.0, green: 31 / 255.0, blue: 31 / 255.0, alpha: 1)
            view.tintColor = self.primaryColor
//            view.separatorInset.left = view.rowHeight
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        if options != nil{
            (view as! UITableView).reloadData()
        }
    }

    @objc dynamic
    var options:[String: Any]? // Bool may be other custom Codable type instead of Any

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Textractor.info.identifier) as! Cell

//        cell.imageView?.image = nil
        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Auto Selection In the Current Area".localized
        cell.textLabel?.textColor = primaryColor
        cell.optionSwitch.setOn(defaults.autoSelect, animated: false)
        cell.switchDidChange = { on in
            self.defaults.autoSelect = on
            AppCenter.default.currentInstanceAs(Textractor.self)?.autoSelect = on
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private class Cell: UITableViewCell {
        lazy var optionSwitch: UISwitch = {
            let view = UISwitch()
            view.addTarget(self, action: #selector(self.cellSwitchDidChange), for: .valueChanged)
            return view
        }()

        var switchDidChange: ((Bool) -> Void)?

        override func prepareForReuse() {
            super.prepareForReuse()

            switchDidChange = nil
        }

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            accessoryView = optionSwitch
//            backgroundColor = .clear
            textLabel?.font = UIFont.systemFont(ofSize: 14)
//            textLabel?.textColor = UIColor.white
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func cellSwitchDidChange(sender: UISwitch) {
            switchDidChange?(sender.isOn)
        }

        override func layoutSubviews() {
            super.layoutSubviews()

//            imageView?.frame.size = CGSize(width: 30, height: 30)
//            imageView?.frame.origin = CGPoint(x: 10, y: (contentView.bounds.height - 30) / 2)

//            textLabel?.frame.origin.x = (imageView?.frame.maxX ?? 0) + 10
        }

        override func tintColorDidChange() {
            super.tintColorDidChange()

            optionSwitch.onTintColor = tintColor
        }
    }
}
