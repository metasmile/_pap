//
//  AutoAdjustment.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

class _AutoEditorAppAsset: _FiltersAppAsset {}

public class AutoEditorApp: NSObject, BApp, KeyPathWatchable, ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
        PhotoPickerCollectionViewDisplayableApp, PhotoPickerViewControllerDelegatableApp, PhotoEditorViewControllerDelegatableApp {

    public static let taskType: AppTaskable.Type = _AutoEditorAppTask.self
    public static let paramType: AppTaskParamable.Type = _AutoEditorAppAsset.self
    
    public static var configure:(() -> FiltersAppConfigValue)?
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = FiltersApp.configure?()
    public private(set) lazy var dockContent: AppDockContent? = AutoEditorAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = AutoEditorAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        var defaults = type(of: self).defaults as! AutoEditorAppDefaults
        
        if let options = (editStateValue?.ciFilter as? CIAutoAdjustmentFilter)?.options {
            var optionsToStore = [String:Bool]()
            for (k,v) in options{
                if let v = v as? Bool{
                    optionsToStore[k] = v
                }
            }
            
            defaults.autoAdjustmentOptions = optionsToStore
        }
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.autoeditor"
        , version: "1.0"
        , phase: .release
        , appType: AutoEditorApp.self
        , displayName: "Auto Editor".localized, description:nil, keywords:nil
        , iconBundleName: R.image.autoEditorBAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()

        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateControllerView()
        }

        let controllerContent = self.dockContent as? AutoEditorAppDockContent
        controllerContent?.watch(\.options, options: [.initial, .new]) {
            if let options = controllerContent?.options {
                let filter = CIAutoAdjustmentFilter(options: options)
                self.config?.filter = CIFilterItem(filter)

            }else{
                var defaults = type(of: self).defaults as! AutoEditorAppDefaults
                controllerContent?.options = defaults.autoAdjustmentOptions
                
                let filter = CIAutoAdjustmentFilter(options: defaults.autoAdjustmentOptions)
                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
                self.defaultEditStateValue = filterItem
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? AutoEditorAppDockContent
        controllerContentInPhotoEditor?.watch(\.options, options: [.initial, .new]) {
            if let options = controllerContentInPhotoEditor?.options {
                let filter = CIAutoAdjustmentFilter(options: options)
                self.config?.filter = CIFilterItem(filter)
                
            } else{
                var defaults = type(of: self).defaults as! AutoEditorAppDefaults
                controllerContentInPhotoEditor?.options = defaults.autoAdjustmentOptions
                
                let filter = CIAutoAdjustmentFilter(options: defaults.autoAdjustmentOptions)
                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
            }
        }
    }

    public var doneButtonTitle: String? {
        return "Apply".localized
    }

    public static var allowExpandablePreview: Bool {
        return true
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.imageType == .stillImage
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.modify]
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
        self.updateControllerView()
    }
    
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original, filtered)
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in dockContent: AppDockContent?) {
        let filter = editStateValue?.ciFilter as? CIAutoAdjustmentFilter
        (dockContent as? AutoEditorAppDockContent)?.switchOptions(filter?.options, animated: false)
    }
}

class CIAutoAdjustmentFilter: CIFilter {
    var options: [String: Any]?
    
    init(options: [String: Any]? = nil) {
        super.init()
        
        self.options = options
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        guard var image = value(forKey: kCIInputImageKey) as? CIImage else { return nil }
        
        for filter in image.autoAdjustmentFilters(options: options) {
            filter.setValue(image, forKey: kCIInputImageKey)
            if let result = filter.outputImage {
                image = result
            }
        }
        
        return image
    }
}

private extension AutoEditorApp {
    struct AutoAdjustments {
        static let Enhance = kCIImageAutoAdjustEnhance
        static let RedEye = kCIImageAutoAdjustRedEye
        static let Crop = kCIImageAutoAdjustCrop
        static let Straighten = kCIImageAutoAdjustLevel

        static func aliasName(_ filterName: String?) -> String? {
            switch filterName {
            case Enhance?: return "Auto Enhance"
            case RedEye?: return "Auto Red-Eye Removal"
            case Crop?: return "Auto Crop"
            case Straighten?: return "Auto Straighten"
            default: return nil
            }
        }

        static func iconImage(_ filterName: String?) -> UIImage? {
            switch filterName {
            case Enhance?: return R.image.auto_enhance()?.withRenderingMode(.alwaysTemplate)
            case RedEye?: return R.image.auto_redeye()?.withRenderingMode(.alwaysTemplate)
            case Crop?: return R.image.auto_crop()?.withRenderingMode(.alwaysTemplate)
            case Straighten?: return R.image.auto_straighten()?.withRenderingMode(.alwaysTemplate)
            default: return nil
            }
        }
    }

    static let AutoAdjustmentsKeys = [
        AutoEditorApp.AutoAdjustments.Enhance,
        AutoEditorApp.AutoAdjustments.Straighten,
        AutoEditorApp.AutoAdjustments.Crop,
        AutoEditorApp.AutoAdjustments.RedEye
    ]
    
    private func updateControllerView(){
        self.dockContent?.view.tintColor = config?.tintColor
        self.photoEditorDockContent?.view.tintColor = config?.tintColor
    }
}

private class _AutoEditorAppTask: AppTaskPrototypeDefaultConcurrencyCountPolicy, AppTaskable {
    public typealias ParamType = _AutoEditorAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _FiltersAppAsset)?.cancelAllRequestIDs()
        (param as? _FiltersAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _AutoEditorAppAsset, "TaskParamable type of this app is \(_FiltersAppAsset.self)")
        guard let _param = param as? _AutoEditorAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _AutoEditorAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            assetItem.runEditing({ (progress) in
                PHAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    result = PHAssetResultItem(
                        asset: asset,
                        contentEditingOutput: contentEditingOutput)
                }
                async.end()
            }
        }
        
        async.waitUntilEnd()
        return result
    }
}

/*
AutoEditorAppDockContent
*/
import DefaultsKit
private protocol AutoEditorAppDefaults: AppDefaults{
    var autoAdjustmentOptions: [String:Bool] {get set}
}

extension Defaults: AutoEditorAppDefaults {
    fileprivate var autoAdjustmentOptions: [String:Bool] {
        set{ set(newValue) }
        get{ return get(or: AutoEditorApp.AutoAdjustmentsKeys.dictionary { ($0, true) } ) }
    }
}

class AutoEditorAppDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    fileprivate static var primaryColor = UIColor(red:0.12, green:0.67, blue:0.98, alpha:1)
    fileprivate var autoAdjustmentOptionKeys = AutoEditorApp.AutoAdjustmentsKeys

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero)
        return tableView
    }()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = (view as! UITableView).rowHeight * CGFloat(autoAdjustmentOptionKeys.count)
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {
        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 52
            view.allowsSelection = false
            view.register(Cell.self, forCellReuseIdentifier: AutoEditorApp.info.identifier)
            view.backgroundColor = .clear
            view.separatorInset.left = view.rowHeight
        }
    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        if options != nil{
            (view as! UITableView).reloadData()
        }
    }
    
    @objc dynamic
    var options:[String: Any]? // Bool may be other custom Codable type instead of Any
    
    func switchOptions(_ options: [String: Any]?, animated: Bool) {
        for (index, cell) in (view as! UITableView).visibleCells.enumerated() {
            let option = (options?[self.autoAdjustmentOptionKeys[index]] as? Bool) ?? false
            (cell as? Cell)?.optionSwitch.setOn(option, animated: animated)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoAdjustmentOptionKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AutoEditorApp.info.identifier) as! Cell
        let filterName = autoAdjustmentOptionKeys[indexPath.row]
        
        cell.imageView?.image = AutoEditorApp.AutoAdjustments.iconImage(filterName)
        
        cell.imageView?.tintColor = AutoEditorAppDockContent.primaryColor
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = AutoEditorApp.AutoAdjustments.aliasName(filterName)
        cell.optionSwitch.onTintColor = cell.imageView?.tintColor
        cell.optionSwitch.setOn((self.options?[self.autoAdjustmentOptionKeys[indexPath.row]] as? Bool) == true, animated: false)
        cell.switchDidChange = { on in
            self.options?[self.autoAdjustmentOptionKeys[indexPath.row]] = on ? true : false
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
            backgroundColor = .clear
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc func cellSwitchDidChange(sender: UISwitch) {
            switchDidChange?(sender.isOn)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            imageView?.frame.size = CGSize(width: 30, height: 30)
            imageView?.frame.origin = CGPoint(x: 10, y: (contentView.bounds.height - 30) / 2)
            
            textLabel?.frame.origin.x = (imageView?.frame.maxX ?? 0) + 10
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
            
            textLabel?.textColor = tintColor
        }
    }
}

