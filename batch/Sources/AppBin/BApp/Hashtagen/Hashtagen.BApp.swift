//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import PropertyKit
import FirebaseMLVision

private typealias HashtagenAppParam = AppAsset
private struct HashtagenAppResult: AppTaskResultable {
    fileprivate let asset:PHAsset
    fileprivate let labels:[String]
}


private protocol HashtagenAppDefaults: AppDefaults{
    var autoSelect: Bool {get set}
}

extension Defaults: HashtagenAppDefaults {
    fileprivate var autoSelect: Bool {
        set{ set(newValue); }
        get{ return get(or: true) }
    }
}

public class HashtagenApp: NSObject, PropertyWatchable, BApp
        , AppDockApp
        , FinalizableApp
        , PhotoPickerViewControllerAppearanceDelegatableApp
        , PhotoPickerCollectionViewDelegatableApp
        , PreheatableApp {
    public static let taskType: AppTaskable.Type = _HashtagenAppTask.self

    public static let paramType: AppTaskParamable.Type = HashtagenAppParam.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.hashtagen"
            , version: "1.0"
            , phase: .develop
            , appType: HashtagenApp.self
            , displayName: "Hashtagen"
            , description: "Restorer allows restoring a bunch amount of edited photos to the original one quickly. Furthermore, it helps you with the automatic selection!".localized
            , keywords: ["Restore","Repair","Hashtagen","recovery", "Restorer"]
            , iconBundleName: R.image.hashtagenBAppIcon.name
            , themeColor: UIColor(rgb: 0xFF29A8)
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    fileprivate lazy var vision = Vision.vision()

    public private(set) lazy var content: AppDockContent? = HashtagenAppDockContent()

    private let appDefaults = HashtagenApp.defaults as! HashtagenAppDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = appDefaults.autoSelect

    required public override init(){
        super.init()
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return true
    }

    public func performPreheating(item: PHAssetParamable,  _ async: AsyncWaitSignalable)  -> PreheatingFinishAction? {
        return appDefaults.autoSelect && item.asset.isAdjusted == true ? UICollectionViewPreheatableAppFinishAction.selectItem : nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        return [AppTaskRespondable]()
    }

    public var titleWillBegin: String? {
        return "Starting to check edited photos...".localized
    }

    public var titleWillFinalize: String? {
        return "Finding Hashtags From Photos...".localized
    }

    public var doneButtonTitle: String? {
        return "Find".localized
    }
}

private struct HashtagenAppDetector{

    private let vision = Vision.vision()

    fileprivate static func isResultFilled(result:VisionTextPHAssetDetectResult?) -> Bool{


        return false
    }


    fileprivate func detectResult(asset:PHAsset, image: UIImage, _ async: AsyncWaitSignalable) -> VisionTextPHAssetDetectResult? {
        guard let visionText = vision.onDeviceTextRecognizer().detect(with: image, async) else {
            return nil
        }

        return nil
    }
}

private class _HashtagenAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is HashtagenAppParam, "TaskParamable type of this app is \(HashtagenAppParam.self)")
        guard let _param = param as? HashtagenAppParam else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ param: HashtagenAppParam, _ async: AsyncWaitSignalable) throws -> HashtagenAppResult?  {

        var results:HashtagenAppResult?

        if let image = param.asset.asUIImage  {
            async.begin()

            AppCenter.default.currentInstanceAs(HashtagenApp.self)?.vision.labelDetector().detect(in: VisionImage(image: image), completion:{ (labels,e) in
                if e == nil, let labels:[VisionLabel] = labels?.nilEmpty{

                    let detectedLabels = labels.sorted { l1, l2 in return l1.confidence > l2.confidence }.map { $0.label }
                    print(detectedLabels)

                    results = HashtagenAppResult(asset: param.asset, labels: detectedLabels)
                }
                async.end()
            })
            async.waitUntilEnd()
        }

        return results
    }
}


/*
HashtagenAppDockContent
*/

fileprivate class HashtagenAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = HashtagenApp.defaults as! HashtagenAppDefaults

    private let primaryColor = HashtagenApp.info.themeColor

    lazy var view: UIView = UITableView()

    var contentScrollable: AppDockContentScrollable? {
        guard let scrollView = view as? UITableView else { return nil }
        return AppDockScrollableContent(scrollView)
    }

    var preferences: AppDockContentPreferable? {
        guard let tableView = view as? UITableView else{
            return nil
        }
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = tableView.rowHeight * CGFloat(1)
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {
        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 52
            view.allowsSelection = false
            view.register(Cell.self, forCellReuseIdentifier: HashtagenApp.info.identifier)
//            view.backgroundColor = UIColor(red: 31 / 255.0, green: 31 / 255.0, blue: 31 / 255.0, alpha: 1)
            view.tintColor = self.primaryColor
//            view.separatorInset.left = view.rowHeight
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        if options != nil{
            (view as? UITableView)?.reloadData()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: HashtagenApp.info.identifier) as! Cell

//        cell.imageView?.image = nil
        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Auto Selection Bot".localized
        cell.imageView?.image = R.image.commonCellIconRobot()?.withRenderingMode(.alwaysTemplate)
        cell.imageView?.tintColor = primaryColor

        cell.optionSwitch.setOn(defaults.autoSelect, animated: false)
        cell.optionSwitch.onTintColor = HashtagenApp.info.themeColor
        cell.switchDidChange = { on in
            self.defaults.autoSelect = on
            AppCenter.default.currentInstanceAs(HashtagenApp.self)?.autoSelect = on
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

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            accessoryView = optionSwitch
//            backgroundColor = .clear
//            textLabel?.font = UIFont.systemFont(ofSize: 14)
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
    }
}

import Intents

extension HashtagenApp:UIApplicationDelegateLaunchableApp{
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenIntent()
            openAppIntent.appId = HashtagenApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: HashtagenApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open Restorer.".localized

            let asb = AutoSelectIntent()
            asb.appId = info.identifier
            asb.appName = openAppIntent.appName
            asb.suggestedInvocationPhrase = "Auto Select on %@.".localizedFormatted(info.displayName)

            return [openAppIntent, asb]
        } else {
            return []
        }
    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

        if #available(iOS 12.0, *) {
            guard let intent = userActivity.interaction?.intent else {
                return
            }

            if intent is AutoSelectIntent{
                var mutableDefaults = self.appDefaults
                mutableDefaults.autoSelect = true
                (self.content?.view as? UITableView)?.reloadData()
            }
        }

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }
}
