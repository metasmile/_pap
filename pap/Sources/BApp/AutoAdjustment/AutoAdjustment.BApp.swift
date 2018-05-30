//
//  AutoAdjustment.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

class _AutoAdjustmentAppAsset: _PhotosFilterAppAsset {}

public class AutoAdjustmentApp: NSObject, BApp, KeyPathWatchable, ConfigurableApp, _ConfigurableApp,
        AppDockControllableApp, PHAssetFinalizableApp, PhotoPickerCollectionViewDisplayableApp,
        PhotoPickerViewControllerDelegatableApp, PreviewableApp {

    public static let taskType:Taskable.Type = _AutoAdjustmentAppTask.self
    public static let paramType:TaskParamable.Type = _AutoAdjustmentAppAsset.self
    
    public static var configure:(() -> PhotosFilterAppConfigValue)?
    
    @objc dynamic
    public private(set) lazy var config: PhotosFilterAppConfigValue? = PhotosFilterApp.configure?()
    public private(set) lazy var dockContent: AppDockContent? = AutoAdjustmentAppDockContent()
    
    public private(set) var currentEditStateValue: ImageEditStateValue?
    
    public static let info = AppInfo(
        identifier: "com.stells.pap.autoadjustment"
        , version: "1.0"
        , phase: .release
        , appType: AutoAdjustmentApp.self
        , displayName: "Auto Edit"
        , icon: R.image.autoAdjustmentBAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()

        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateControllerView()
        }

        let controllerContent = self.dockContent as? AutoAdjustmentAppDockContent
        controllerContent?.watch(\.options, options: [.initial, .new]) {

            var defaults = type(of: self).defaults as! AutoAdjustmentAppDefaults

            if let options = controllerContent?.options {
                let filter = CIAutoAdjustmentFilter(options: options)
                self.config?.filter = CIFilterItem(filter)
                self.currentEditStateValue = CIFilterItem(filter)

                var optionsToStore = [String:Bool]()
                for (k,v) in options{
                    if let v = v as? Bool{
                        optionsToStore[k] = v
                    }
                }

                defaults.autoAdjustmentOptions = optionsToStore

            }else{
                controllerContent?.options = defaults.autoAdjustmentOptions
                
                let filter = CIAutoAdjustmentFilter(options: defaults.autoAdjustmentOptions)
                self.currentEditStateValue = CIFilterItem(filter)
            }
        }
    }

    public var doneButtonTitle: String? {
        return "Apply".localized
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
}

class CIAutoAdjustmentFilter: CIFilter {
    private var options: [String: Any]?
    
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

private extension AutoAdjustmentApp {
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
        AutoAdjustmentApp.AutoAdjustments.Enhance,
        AutoAdjustmentApp.AutoAdjustments.RedEye,
        AutoAdjustmentApp.AutoAdjustments.Crop,
        AutoAdjustmentApp.AutoAdjustments.Straighten
    ]
    
    private func updateControllerView(){
        self.dockContent?.view.tintColor = config?.tintColor
    }
}

private class _AutoAdjustmentAppTask: TaskPrototype, Taskable {
    public typealias ParamType = _AutoAdjustmentAppAsset
    public typealias ResultType = PHAssetResultItem

    override var info: TaskInfo {
        let info = super.info

        if let param = info.requestParam as? _AutoAdjustmentAppAsset{
            let pixelAmount = param.asset.pixelWidth*param.asset.pixelHeight
            if pixelAmount > 3000*3000{
                info.policy.estimatedConcurrencyCount = 1

            }else if pixelAmount > 2000*2000{
                info.policy.estimatedConcurrencyCount = 2

            }else {
                info.policy.estimatedConcurrencyCount = nil
            }
        }else{
            //default is undefined.
            info.policy.estimatedConcurrencyCount = nil
        }

        return info

    }
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){
        
        (param as? _PhotosFilterAppAsset)?.cancelAllRequestIDs()
        (param as? _PhotosFilterAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        assert(param is _AutoAdjustmentAppAsset, "TaskParamable type of this app is \(_PhotosFilterAppAsset.self)")
        guard let _param = param as? _AutoAdjustmentAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _AutoAdjustmentAppAsset, _ async: AsyncManualSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        assetItem.runEditing({ (progress) in
            guard let progress = progress else { return }
            NotificationCenter.default.post(name: PHAssetProcessableNotification.Name.progressChanged, object: self, userInfo: [
                PHAssetProcessableNotification.UserInfo.Key.progress: progress,
                PHAssetProcessableNotification.UserInfo.Key.assetItem: assetItem
                ])
        }) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                    asset: asset,
                    contentEditingOutput: contentEditingOutput)
            }
            async.end()
        }
        
        async.waitUntilEnd()
        return result
    }
}

/*
AutoAdjustmentAppDockContent
*/
import DefaultsKit
private protocol AutoAdjustmentAppDefaults: AppDefaults{
    var autoAdjustmentOptions: [String:Bool] {get set}
}

extension Defaults: AutoAdjustmentAppDefaults {
    fileprivate var autoAdjustmentOptions: [String:Bool] {
        set{ set(newValue) }
        get{ return get(or: AutoAdjustmentApp.AutoAdjustmentsKeys.dictionary { ($0, true) } ) }
    }
}

class AutoAdjustmentAppDockContent: NSObject, KeyPathWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    fileprivate var autoAdjustmentOptionKeys = AutoAdjustmentApp.AutoAdjustmentsKeys

    lazy var view: UIView = UITableView()

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = (view as! UITableView).rowHeight * CGFloat(autoAdjustmentOptionKeys.count)
        preferences.displayMode = .pinned
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {
        if let view = view as? UITableView{
            view.dataSource = self
            view.delegate = self
            view.rowHeight = 52
            view.allowsSelection = false
            view.register(Cell.self, forCellReuseIdentifier: AutoAdjustmentApp.info.identifier)
            view.backgroundColor = UIColor(red: 31 / 255.0, green: 31 / 255.0, blue: 31 / 255.0, alpha: 1)
            view.tintColor = UIColor(red: 72 / 255.0, green: 168 / 255.0, blue: 247 / 255.0, alpha: 1)
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoAdjustmentOptionKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AutoAdjustmentApp.info.identifier) as! Cell
        let filterName = autoAdjustmentOptionKeys[indexPath.row]
        
        cell.imageView?.image = AutoAdjustmentApp.AutoAdjustments.iconImage(filterName)
        //TODO: apply AppearancableApp.primaryColor
        cell.imageView?.tintColor = UIColor.white
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = AutoAdjustmentApp.AutoAdjustments.aliasName(filterName)
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
            textLabel?.font = UIFont.systemFont(ofSize: 14)
            textLabel?.textColor = UIColor.white
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
            
            optionSwitch.onTintColor = tintColor
        }
    }
}

