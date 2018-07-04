//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import DefaultsKit

private typealias RevertAppParam = PHAssetItem<ImageEditStateValue>
private struct RevertAppResult: AppTaskResultable {
    fileprivate let asset:PHAsset
    fileprivate let isAdjusted:Bool
}


private protocol RevertAppDefaults: AppDefaults{
}

extension Defaults: RevertAppDefaults {
}

public class RevertApp: NSObject, KeyPathWatchable, BApp
        , AppDockApp
        , FinalizableApp, AppManagerDelegatedApp
        , PhotoPickerViewControllerDelegatableApp
        , PhotoPickerCollectionViewDisplayableApp
        , PreheatableApp {
    public static let taskType: AppTaskable.Type = _RevertAppTask.self

    public static let paramType: AppTaskParamable.Type = RevertAppParam.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.revert"
            , version: "1.0"
            , phase: .release
            , appType: RevertApp.self
            , displayName: "Revert", description:nil, keywords:nil
            , iconBundleName: R.image.revertBAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public private(set) lazy var dockContent: AppDockContent? = RevertAppDockContent()

    private let appDefaults = RevertApp.defaults as! RevertAppDefaults

    @objc dynamic
    public fileprivate (set) lazy var autoSelect: Bool = false

    required public override init(){
        super.init()
    }

    fileprivate var adjustedCache = [String:Bool]()

    func willSetCurrent(oldCurrent: App.Type?) {
        adjustedCache.removeAll()
    }

    func didSetCurrent(previous: App.Type?) {}

    public func shouldSelect(item: AppAsset) -> Bool {
        return true
    }

    public func performPreheating(item: AppAsset, _ async: AsyncSignal) -> PreheatingFinishAction? {
        return self.autoSelect && item.asset.isAdjusted == true ? UICollectionViewPreheatableAppFinishAction.selectItem : nil
    }

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let adjustedAssets = result.compactMap { r -> PHAsset? in
            let result = r.result as? RevertAppResult
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
                for asset in adjustedAssets {
                    self.adjustedCache[asset.localIdentifier] = false
                }
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
        return "Reverting Photos...".localized
    }
}

private class _RevertAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncManualSignalable){}

    public func perform(_ param: AppTaskParamable, _ async: AsyncManualSignalable) throws -> AppTaskResultable? {
        assert(param is RevertAppParam, "TaskParamable type of this app is \(RevertAppParam.self)")

        guard let _param = param as? RevertAppParam else{
            throw AppTaskError.invalidParam
        }

        return RevertAppResult(asset: _param.asset, isAdjusted: _param.asset.isAdjusted)
    }
}


/*
RevertAppDockContent
*/

fileprivate class RevertAppDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    private lazy var defaults = RevertApp.defaults as! RevertAppDefaults

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
            view.register(Cell.self, forCellReuseIdentifier: RevertApp.info.identifier)
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

    private var autoSelect:Bool = false

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RevertApp.info.identifier) as! Cell

//        cell.imageView?.image = nil
        cell.imageView?.tintColor = primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = "Enable Auto Selection".localized
        cell.textLabel?.textColor = primaryColor
        cell.optionSwitch.setOn(self.autoSelect, animated: false)
        cell.switchDidChange = { on in
            self.autoSelect = on
            AppCenter.default.currentInstanceAs(RevertApp.self)?.autoSelect = on
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

        override func tintColorDidChange() {
            super.tintColorDidChange()

            optionSwitch.onTintColor = tintColor
        }
    }
}

