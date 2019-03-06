//
//  ColorEditor.BApp.swift
//  pap
//
//  Created by HYOJIN MO on 28/02/2019.
//  Copyright © 2019 Stells. All rights reserved.
//

import UIKit
import PropertyKit
import Photos

protocol ColorEditorDefaults: AppDefaults {
    var colorFilters: [CIBuiltInFilter] { get set }
}

extension Defaults: ColorEditorDefaults {
    internal var colorFilters: [CIBuiltInFilter] {
        set { set(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get { return get(or: []) }
    }
}

class ColorEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {
    public static let taskType: AppTaskable.Type = ColorEditorTask.self
    
    public static let paramType: AppTaskParamable.Type = _ColorEditorAppAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = ColorEditorAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = ColorEditorAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        if var defaults = type(of: self).defaults as? ColorEditorDefaults, let filter = editStateValue?.ciFilter as? CIColorFilterGroup {
            defaults.colorFilters = filter.filters
        }
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.coloreditor"
        , version: "0.1"
        , phase: .develop
        , appType: ColorEditorApp.self
        , displayName: "Color Tool".localized.localizedCapitalized, description:nil, keywords:nil
        , iconBundleName: nil
        , themeColor: UIColor(red: 1.0, green: 0, blue: 0, alpha: 1)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        let controllerContent = self.content as? ColorEditorAppDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? ColorEditorDefaults {
                let filter = CIColorFilterGroup(filters: defaults.colorFilters)

                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
                self.defaultEditStateValue = filterItem
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? ColorEditorAppDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? ColorEditorDefaults {
                let filter = CIColorFilterGroup(filters: defaults.colorFilters)

                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
            }
        }
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.actions]
    }
    
    public static var fixedContentLayout: Bool {
        return true
    }
    
    public var doneButtonTitle: String? {
        return "Apply".localized
    }
    
    public func shouldSelect(item: AppAsset) -> Bool {
        return true
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    //INFO: prevent memory leak for creating CIImage(uiImage:)
    public lazy var previewOriginalImageCache: NSCache<NSString, CIImage>? = NSCache<NSString, CIImage>()
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = cachedOriginalImage(with: appAsset.asset, targetSize: targetSize)
        
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original?.asUIImage, filtered?.asUIImage)
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        if let filter = editStateValue?.ciFilter as? CIColorFilterGroup {
            (content as? ColorEditorAppDockContent)?.setFilterValues(filter, animated: false)
            
//            if self.undoStack.isEmpty {
//                self.registerUndo(filter.filterAttributes)
//            }
        }
    }
}

fileprivate class CIToneCurveFilter: CIBuiltInFilter {
    convenience init() {
        self.init(name: "CIToneCurve", editableItems: [
            CIFilterAttributeItem(name: "Blacks".localized, attributeKey: "inputPoint0", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Shadows".localized, attributeKey: "inputPoint1", defaultValue: 0.25, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Midtones".localized, attributeKey: "inputPoint2", defaultValue: 0.5, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Highlights".localized, attributeKey: "inputPoint3", defaultValue: 0.75, minimumValue: 0, maximumValue: 1, offset: 1),
            CIFilterAttributeItem(name: "Whites".localized, attributeKey: "inputPoint4", defaultValue: 1.0, minimumValue: 0, maximumValue: 1, offset: 1)
        ])
    }
}

fileprivate class CIColorFilterGroup: CIFilterGroup<CIBuiltInFilter> {
    var filterAttributes: [CIFilterAttributes] {
        return filters.map { $0.filterAttributes.values }.reduce([], +)
    }
}

class _ColorEditorAppAsset: _FiltersAppAsset {}

struct ColorEditorResultItem: AppTaskResultable {
    var asset: PHAsset
    var result: [PHAssetEditingResultItem]?
    
    init(asset: PHAsset, result: [PHAssetEditingResultItem]?) {
        self.asset = asset
        self.result = result
    }
}

public class ColorEditorValue: ImageEditStateValue {}

private class ColorEditorTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _ColorEditorAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _ColorEditorAppAsset)?.cancelAllRequestIDs()
        (param as? _ColorEditorAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _ColorEditorAppAsset, "TaskParamable type of this app is \(_ColorEditorAppAsset.self)")
        guard let _param = param as? _ColorEditorAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _ColorEditorAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    let filterAttributes = (assetItem.editState.ciFilter as? CIColorFilterGroup)?.filters.map({ $0.filterAttributes.values }).reduce([], +) ?? []
                    
                    var editInfo: [String: Any] = [:]
                    if let jsonData = try? JSONEncoder().encode(filterAttributes), let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? Array<Any> {
                        editInfo["filterAttributes"] = json
                    }
                    
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: ColorEditorApp.self, editInfo: editInfo, from: asset)
                    
                    result = PHAssetResultItem(
                        asset: assetItem,
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

class ColorEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent, AppDockDelegate, UITableViewDelegate, UITableViewDataSource {
    lazy var view: UIView = {
        let view = UITableView(frame: .zero)
        view.dataSource = self
        view.delegate = self
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 52
        view.allowsSelection = false
        view.register(CIAdjustmentSliderCell.self, forCellReuseIdentifier: ColorEditorApp.info.identifier + "\(CIAdjustmentSliderCell.self)")
        view.backgroundColor = .clear
        view.separatorStyle = .none
        return view
    }()
    
    var preferences: AppDockContentPreferable? {
        guard let tableView = view as? UITableView else{
            return nil
        }
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = tableView.estimatedRowHeight * 5
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        
        if colorFilters.isEmpty {
            installFilters()
        }
        
        (view as? UITableView)?.reloadData()
    }
    
    @objc dynamic var filter: CIFilter?
    
    fileprivate var colorFilters = [CIBuiltInFilter]()
    
    private func installFilters(with filters: [CIBuiltInFilter]? = nil) {
        colorFilters.removeAll()
        
        if let filters = filters, !filters.isEmpty {
            colorFilters = filters
        }
        else {
            colorFilters = [CIToneCurveFilter()]
        }
    }
    
    fileprivate func setFilterValues(_ filter: CIColorFilterGroup?, animated: Bool = true) {
        guard let tableView = view as? UITableView, let filter = filter?.copy() as? CIColorFilterGroup else { return }
        
        self.installFilters(with: filter.filters)
        
        DispatchQueue.main.async {
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return colorFilters.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorFilters[safe: section]?.editableItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ColorEditorApp.info.identifier + "\(CIAdjustmentSliderCell.self)") as! CIAdjustmentSliderCell
        
        let filter = colorFilters[indexPath.section]
        
        guard let attributeItem = filter.editableItems?[indexPath.item] else { return cell }
        
        cell.titleLabel.text = attributeItem.name
        
        cell.highlightedColor = ColorEditorApp.info.themeColor
        
        cell.slider.minimumValue = attributeItem.minimumValue
        cell.slider.maximumValue = attributeItem.maximumValue
        cell.slider.defaultValue = attributeItem.defaultValue
        cell.slider.value = attributeItem.value
        
        cell.resetButton.isHidden = !attributeItem.hasChanges
        cell.resetButtonDidTapHandler = {
            attributeItem.value = attributeItem.defaultValue
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            cell.slider.value = attributeItem.value
            
//            self.markAsSelectedFilterAttribiutes((self.filter as? CIAdjustmentFilterGroup)?.filterAttributes)
            self.filter = CIColorFilterGroup(filters: self.colorFilters)
        }
        
        cell.sliderDidChangeHandler = { value in
            attributeItem.value = value
            
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            DispatchQueue.main.async {
                self.filter = CIColorFilterGroup(filters: self.colorFilters)
            }
        }
        
        cell.sliderDidEndHandler = {
//            let filter = self.filterManager.ciFilter
//            self.markAsSelectedFilterAttribiutes(filter.filterAttributes)
            self.filter = CIColorFilterGroup(filters: self.colorFilters)
        }
        
        return cell
    }
    
//    private func markAsSelectedFilterAttribiutes(_ filterAttributes: [CIFilterAttributes]?) {
//        guard let filterAttributes = filterAttributes else { return }
//        self.app?.registerUndo(filterAttributes.compactMap({ $0.copy() as? CIFilterAttributes }))
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
