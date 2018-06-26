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
}

extension Defaults: TextractorDefaults {
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
    public fileprivate (set) lazy var autoSelect: Bool = false
    
    public static let info = AppInfo(
            identifier: "com.stells.pap.textractor"
            , version: "0.1"
            , phase: .develop
            , appType: Textractor.self
            , displayName: "Textractor", description:nil, keywords:nil
            , iconBundleName: nil
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy.default, task: TaskPolicy(cancellation: .shallow, priority: .normal, estimatedConcurrencyCount: 1))
            , minOSVersion: nil
    )

    public required override init() {

    }

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
        if self.autoSelect == false{
            return .none
        }

        if let image = item.asset.asUIImage
            , let detectedString = self.textDetector.detect(with: image, async)?.parse(type: VisionTextStringParser.self, async)?.joined() {

            return detectedString.count>0 ? .visible : .none
        }

        return .none
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

    fileprivate var textDetector = Vision.vision().textDetector()
}

private class _TextractorTask: TaskPrototype, Taskable {

    private let emailParser = VisionTextEmailAddressParser()
    private let phoneNumberParser = VisionTextPhoneNumberParser()

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {

        guard let asset = (param as? PHAssetItem<ImageEditStateValue>)?.asset
            , let image = asset.asUIImage else {

            return nil
        }

        guard let detector = AppCenter.default.currentInstanceAs(Textractor.self)?.textDetector
            ,let visionTexts = detector.detect(with: image, async) else {

            return nil
        }


        //String
        let rawString = visionTexts.parse(type: VisionTextStringParser.self, async)?.joined()

        let phoneNumbers = visionTexts.parse(type: VisionTextPhoneNumberParser.self, async)

        let emailAddresses = visionTexts.parse(type: VisionTextEmailAddressParser.self, async)

        return TextractorResult(asset: asset, text: rawString ?? "")
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

    private var autoSelect:Bool = false

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

        cell.textLabel?.text = "Enable Auto Selection".localized
        cell.textLabel?.textColor = primaryColor
        cell.optionSwitch.setOn(self.autoSelect, animated: false)
        cell.switchDidChange = { on in
            self.autoSelect = on
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
