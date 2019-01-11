//
//  AutoAdjustment.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 17..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

class _AutoEditorAppAsset: _FiltersAppAsset {}

public class AutoEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
        PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {

    public static let taskType: AppTaskable.Type = _AutoEditorAppTask.self
    public static let paramType: AppTaskParamable.Type = _AutoEditorAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }

    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue

    public private(set) lazy var content: AppDockContent? = AutoEditorAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = AutoEditorAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        var defaults = type(of: self).defaults as! AutoEditorAppDefaults
        
        if let options = (editStateValue?.ciFilter as? CIAutoAdjustmentFilter)?.options {
            var optionsToStore = [String:Bool]()
            for (k,v) in options{
                optionsToStore[k] = v
            }
            
            defaults.autoAdjustmentOptions = optionsToStore
        }
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.autoeditor"
        , version: "1.0"
        , phase: .release
        , appType: AutoEditorApp.self
        , displayName: "Auto Editor".localized.localizedCapitalized
        , description: "Auto Editor lets you edit automatically if your photos are needed to correct.".localized
        , keywords: ["photo editor", "photos", "enhancement", "crop", "red-eye removal", "fix", "quality"]
        , iconBundleName: R.image.autoEditorBAppIcon.name
            , themeColor: UIColor(red:0, green:1, blue:0.964, alpha:1)
            , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()

        let controllerContent = self.content as? AutoEditorAppDockContent
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

    public static var fixedContentLayout: Bool {
        return true
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.imageType == .stillImage
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.actions]
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original, filtered)
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        let filter = editStateValue?.ciFilter as? CIAutoAdjustmentFilter
        (content as? AutoEditorAppDockContent)?.switchOptions(filter?.options, animated: false)
    }
}

class CIAutoAdjustmentFilter: CIFilter {
    var options: [String: Bool]?
    
    init(options: [String: Bool]? = nil) {
        super.init()
        
        self.options = options
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {

        guard var image = inputImage else { return nil }
        guard let optionsDict = options?.dictionary(transform: { o -> (key: CIImageAutoAdjustmentOption, value: Bool) in
            return (CIImageAutoAdjustmentOption(rawValue: o.key), o.value)
            
        }) else{
            return nil
        }

        //First priority - system filter
        var targetFilters = image.autoAdjustmentFilters(options: optionsDict)

        //Second priority - exclusive filter
        for (option, enable) in optionsDict where enable{
            if let exclusiveFilter = option.acquireExclusiveFilter(){
                targetFilters.append(exclusiveFilter)
            }
        }
        
        for filter in targetFilters {
            filter.setValue(image, forKey: kCIInputImageKey)
            if let result = filter.outputImage {
                image = result
            }
        }
        
        return image
    }
}

extension CIImageAutoAdjustmentOption {

    public func acquireExclusiveFilter(with options:[String:Any]?=nil) -> CIFilter?{
        return autoreleasepool { //can't believe cifilter's constructor.
            switch (self){
                case type(of: self).someOtherAutoEditorOption:
                return nil
            default:
                return nil
            }
        }
    }

    public static let someOtherAutoEditorOption = CIImageAutoAdjustmentOption(rawValue: "skinSmoothing")
}

private extension AutoEditorApp {
    struct AutoAdjustments {
        static let Enhance = CIImageAutoAdjustmentOption.enhance
        static let RedEye = CIImageAutoAdjustmentOption.redEye
        static let Crop = CIImageAutoAdjustmentOption.crop
        static let Straighten = CIImageAutoAdjustmentOption.level

        static func aliasName(_ option: CIImageAutoAdjustmentOption) -> String? {
            switch option {
            case Enhance: return "Auto Enhance".localized
            case RedEye: return "Red-Eye Removal".localized
            case Crop: return "Auto Crop".localized
            case Straighten: return "Auto Straighten".localized
            default: return nil
            }
        }

        static func iconImage(_ option: CIImageAutoAdjustmentOption) -> UIImage? {
            switch option {
            case Enhance: return R.image.auto_enhance()?.withRenderingMode(.alwaysTemplate)
            case RedEye: return R.image.auto_redeye()?.withRenderingMode(.alwaysTemplate)
            case Crop: return R.image.auto_crop()?.withRenderingMode(.alwaysTemplate)
            case Straighten: return R.image.auto_straighten()?.withRenderingMode(.alwaysTemplate)
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
}

private class _AutoEditorAppTask: AppTaskPrototype, AppTaskable {
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
        
        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: AutoEditorApp.self, editInfo: (assetItem.editState.ciFilter as? CIAutoAdjustmentFilter)?.options ?? [:], from: asset)
                    
                    result = PHAssetResultItem(
                        asset: asset,
                        editingResultItems: editingResultItems,
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
import PropertyKit
private protocol AutoEditorAppDefaults: AppDefaults{
    var autoAdjustmentOptions: [String:Bool] {get set}
}

extension Defaults: AutoEditorAppDefaults {
    fileprivate var autoAdjustmentOptions: [String:Bool] {
        set{ set(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get{ return get(or: AutoEditorApp.AutoAdjustmentsKeys.dictionary { ($0.rawValue, true) } ) }
    }
}

class AutoEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    fileprivate static var primaryColor = AutoEditorApp.info.themeColor
    fileprivate var autoAdjustmentOptionKeys = AutoEditorApp.AutoAdjustmentsKeys

    lazy var view: UIView = {
        let tableView = UITableView(frame: .zero)
        return tableView
    }()
    
    var contentScrollable: AppDockContentScrollable? {
        guard let scrollView = view as? UITableView else { return nil }
        return AppDockScrollableContent(scrollView)
    }

    var preferences: AppDockContentPreferable? {
        guard let tableView = view as? UITableView else{
            return nil
        }
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = tableView.rowHeight * min(CGFloat(autoAdjustmentOptionKeys.count), 4.5)
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
        view.tintColor = view.colorTheme.tintColor
        
        if options != nil{
            (view as? UITableView)?.reloadData()
        }
    }
    
    @objc dynamic
    var options:[String: Bool]? // Bool may be other custom Codable type instead of Any
    
    func switchOptions(_ options: [String: Bool]?, animated: Bool) {
        guard let tableView = self.view as? UITableView else{
            return
        }

        for (index, cell) in tableView.visibleCells.enumerated() {
            let option = options?[self.autoAdjustmentOptionKeys[index].rawValue] ?? false
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
        cell.optionSwitch.onTintColor = AutoEditorAppDockContent.primaryColor
        cell.optionSwitch.setOn(self.options?[self.autoAdjustmentOptionKeys[indexPath.row].rawValue] == true, animated: false)
        cell.switchDidChange = { on in
            self.options?[self.autoAdjustmentOptionKeys[indexPath.row].rawValue] = on ? true : false
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



import Intents

private extension CIImageAutoAdjustmentOption{

    var intentActionName:String{
        if let n = AutoEditorApp.AutoAdjustments.aliasName(self){
            return "Apply %@ to the last item".localizedFormatted(n)
        }
        return "Undefined"
    }
}

extension AutoEditorApp: UIApplicationDelegateLaunchableApp {

    static var intents: [INIntent]{
        if #available(iOS 12.0, *) {
            return defaultIntents + AutoEditorApp.AutoAdjustmentsKeys.map({ intentTo(do:$0.intentActionName) })
        } else{
            return []
        }
    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

        if #available(iOS 12.0, *) {
            guard let intent = userActivity.interaction?.intent else {
                return
            }

            //TODO: impl
            if let i = intent as? DoAnyIntent, let name = i.doWhat{

                if name == AutoEditorApp.AutoAdjustments.Enhance.intentActionName{

                }
                else if name == AutoEditorApp.AutoAdjustments.Straighten.intentActionName{

                }
                else if name == AutoEditorApp.AutoAdjustments.Crop.intentActionName{

                }
                else if name == AutoEditorApp.AutoAdjustments.RedEye.intentActionName{

                }

            }
        }

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }

}

