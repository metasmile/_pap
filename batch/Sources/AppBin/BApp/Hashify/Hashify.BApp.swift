//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import PropertyKit

private typealias HashifyAppParam = AppAsset
private struct HashifyAppResult: AppTaskResultable {
    fileprivate let asset:PHAsset
    fileprivate let isAdjusted:Bool
}


private protocol HashifyAppDefaults: AppDefaults{
    var autoSelect: Bool {get set}
}

extension Defaults: HashifyAppDefaults {
    fileprivate var autoSelect: Bool {
        set{ set(newValue); }
        get{ return get(or: true) }
    }
}

public class HashifyApp: NSObject, PropertyWatchable, BApp
        , AppDockApp
        , FinalizableApp
        , PhotoPickerViewControllerAppearanceDelegatableApp
        , PhotoPickerCollectionViewDelegatableApp
        , PreheatableApp
        , ChargeableApp {
    public static let taskType: AppTaskable.Type = _HashifyAppTask.self

    public static let paramType: AppTaskParamable.Type = HashifyAppParam.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.hashify"
            , version: "1.0"
            , phase: .develop
            , appType: HashifyApp.self
            , displayName: "Hashify"
            , description: "Restorer allows restoring a bunch amount of edited photos to the original one quickly. Furthermore, it helps you with the automatic selection!".localized
            , keywords: ["Restore","Repair","Hashify","recovery", "Restorer"]
            , iconBundleName: R.image.hashifyBAppIcon.name
            , themeColor: UIColor(rgb: 0xFF29A8)
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    static var localCharges: [Charge] {
        return self.defaultFreeBAppLocalCharges
    }

    public private(set) lazy var content: AppDockContent? = HashifyAppDockContent()

    private let appDefaults = HashifyApp.defaults as! HashifyAppDefaults

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
        let adjustedAssets = result.compactMap { r -> PHAsset? in
            let result = r.result as? HashifyAppResult
            return result?.isAdjusted == true ? result?.asset : nil
        }

        guard adjustedAssets.count > 0 else {

            asyncSignal.begin()
            DispatchQueue.main.async {
                UIAlertController.alert("Cannot revert. All selected items have not edited.".localized, completion:{ _ in
                    asyncSignal.end()
                })
            }
            asyncSignal.waitUntilEnd()

            return result
        }

        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            for asset in adjustedAssets {
                PHAssetChangeRequest(for: asset).revertAssetContentToOriginal()
            }
        }, completionHandler: { success, error in
            if success {

            }else{
                print("[!] Can't revert asset: \(String(describing: error))")
            }
            asyncSignal.end()
        })

        asyncSignal.waitUntilEnd()
        return result
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

private class _HashifyAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is HashifyAppParam, "TaskParamable type of this app is \(HashifyAppParam.self)")
        guard let _param = param as? HashifyAppParam else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ revertParam: HashifyAppParam, _ async: AsyncWaitSignalable) throws -> HashifyAppResult?  {
        guard revertParam.asset.isAdjusted else { return HashifyAppResult(asset: revertParam.asset, isAdjusted: revertParam.asset.isAdjusted) }

        async.begin()

        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            //INFO: prepare original version of asset
            // it may get original version from icloud to local
            PHImageManager.default().touchOriginalVersion(for: revertParam.asset, completion: {
                async.end()
            })
        }

        async.waitUntilEnd()
        return HashifyAppResult(asset: revertParam.asset, isAdjusted: revertParam.asset.isAdjusted)
    }
}


/*
HashifyAppDockContent
*/

fileprivate class HashifyAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = HashifyApp.defaults as! HashifyAppDefaults

    private let primaryColor = HashifyApp.info.themeColor

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
            view.register(Cell.self, forCellReuseIdentifier: HashifyApp.info.identifier)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: HashifyApp.info.identifier) as! Cell

//        cell.imageView?.image = nil
        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Auto Selection Bot".localized
        cell.imageView?.image = R.image.commonCellIconRobot()?.withRenderingMode(.alwaysTemplate)
        cell.imageView?.tintColor = primaryColor

        cell.optionSwitch.setOn(defaults.autoSelect, animated: false)
        cell.optionSwitch.onTintColor = HashifyApp.info.themeColor
        cell.switchDidChange = { on in
            self.defaults.autoSelect = on
            AppCenter.default.currentInstanceAs(HashifyApp.self)?.autoSelect = on
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

extension HashifyApp:UIApplicationDelegateLaunchableApp{
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenIntent()
            openAppIntent.appId = HashifyApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: HashifyApp.info.displayName) as String
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
