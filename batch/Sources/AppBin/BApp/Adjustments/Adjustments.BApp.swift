//
//  Adjustments.BApp.swift
//  batch
//
//  Created by HYOJIN MO on 26/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

class _AdjustmentsAppAsset: _FiltersAppAsset {}

public class AdjustmentsApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {
    
    public static let taskType: AppTaskable.Type = _AdjustmentsAppTask.self
    public static let paramType: AppTaskParamable.Type = _AdjustmentsAppAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = AdjustmentsAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = AdjustmentsAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        var defaults = type(of: self).defaults as! AdjustmentsAppDefaults
        
//        if let options = (editStateValue?.ciFilter as? CIFilter)?.options {
//            var optionsToStore = [String:Bool]()
//            for (k,v) in options{
//                optionsToStore[k] = v
//            }
//
//            defaults.autoAdjustmentOptions = optionsToStore
//        }
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.adjustments"
        , version: "1.0"
        , phase: .develop
        , appType: AdjustmentsApp.self
        , displayName: "Adjustments".localized.localizedCapitalized
        , description: "Adjustments lets you edit manually your photos.".localized
        , keywords: ["adjustments", "brightness", "constrast", "highlight", "shadow", "saturate", "vibrance"]
        , iconBundleName: nil
        , themeColor: UIColor(red:1, green:0.964, blue:0, alpha:1)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        let controllerContent = self.content as? AdjustmentsAppDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
                
            } else {
                var defaults = type(of: self).defaults as! AdjustmentsAppDefaults
//                controllerContent?.options = defaults.autoAdjustmentOptions
//
//                let filter = CIAdjustmentFilter(options: defaults.autoAdjustmentOptions)
//                let filterItem = CIFilterItem(filter)
//                self.config?.filter = filterItem
//                self.defaultEditStateValue = filterItem
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? AdjustmentsAppDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
                
            } else{
                var defaults = type(of: self).defaults as! AdjustmentsAppDefaults
//                controllerContentInPhotoEditor?.options = defaults.autoAdjustmentOptions
                
//                let filter = CIAdjustmentFilter(value: defaults.double)
//                let filterItem = CIFilterItem(filter)
//                self.config?.filter = filterItem
            }
        }
    }
    
    public var doneButtonTitle: String? {
        return "Apply".localized
    }
    
    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.imageType == .stillImage || item.asset.imageType == .livePhoto || item.asset.imageType == .burst || item.asset.mediaType == .video
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.modify]
    }
    
    public static var fixedContentLayout: Bool {
        return true
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
        let filter = editStateValue?.ciFilter as? CIFilterGroup
        (content as? AdjustmentsAppDockContent)?.setFilterValues(filter, animated: false)
    }
}

class AdjustmentValue {
    var key: String
    var value: Float?
    var defaultValue: Float?
    var minimumValue: Float?
    var maximumValue: Float?
    
    private var attributeType: String?
    private var attributeClass: AnyClass?
    
    init(key: String) {
        self.key = key
    }
    
    func setDefaults(with filter: CIFilter?) {
        guard let attributes = filter?.attributes[key] as? [String: Any] else { return }
        
        attributeType = attributes[kCIAttributeType] as? String
        attributeClass = NSClassFromString(attributes[kCIAttributeClass] as? String ?? "")
        
        if attributeType == kCIAttributeTypeScalar, attributeClass == NSNumber.self {
            self.defaultValue = defaultValue ?? attributes[kCIAttributeDefault] as? Float ?? 0
            self.minimumValue = minimumValue ?? attributes[kCIAttributeSliderMin] as? Float ?? 0
            self.maximumValue = maximumValue ?? attributes[kCIAttributeSliderMax] as? Float ?? 0
        }
        else if attributeType == kCIAttributeTypeOffset, attributeClass == CIVector.self {
            
        }
        
        value = defaultValue
    }
}

class CITemperatureAndTintFilter: CIBuiltInFilter {
    override func setAdjustmentValues(to filter: CIFilter) {
        
    }
}

class CIBuiltInFilter: CIFilter {
    private(set) var adjustmentValues = [String: AdjustmentValue]()
    private var builtInFilter: CIFilter?
    fileprivate var adjustmentName: AdjustmentsApp.Adjustments.Name?
    var filter: CIFilter {
        return builtInFilter ?? self
    }
    
    init(adjustmentName: AdjustmentsApp.Adjustments.Name, adjustments: [AdjustmentValue]? = nil) {
        super.init()
        
        self.name = adjustmentName.builtInFilterName
        self.builtInFilter = CIFilter(name: adjustmentName.builtInFilterName)
        
        self.adjustmentName = adjustmentName
        
        for adjustment in adjustments ?? [] {
            adjustment.setDefaults(with: self.filter)
            self.adjustmentValues[adjustment.key] = adjustment
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return (name == (object as? CIFilter)?.name) == true
    }
    
    open func setAdjustmentValues(to filter: CIFilter) {
        adjustmentValues.forEach { filter.setValue($0.value.value, forKey: $0.value.key) }
    }
    
    func adjustmentValue(forKey key: String) -> AdjustmentValue? {
        let value = adjustmentValues[key] ?? { () -> AdjustmentValue in
            let adjustmentValue = AdjustmentValue(key: key)
            adjustmentValue.setDefaults(with: self.filter)
            return adjustmentValue
        }()
        adjustmentValues[key] = value
        return value
    }
    
    func setAdjustmentValue(_ value: Float, forKey key: String) {
        adjustmentValue(forKey: key)?.value = value
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        guard let image = value(forKey: kCIInputImageKey) as? CIImage else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        setAdjustmentValues(to: filter)
        return filter.outputImage
    }
}

class CIAdjustmentsFilterItem {
    private var orderedFilters = NSMutableOrderedSet()
    
    func setAdjustmentFilter(_ filter: CIFilter?)  {
        guard let filter = filter, !orderedFilters.contains(filter) else { return }
        orderedFilters.add(filter)
    }
    
    func adjustmentFilter(with filter: CIFilter?) -> CIFilter? {
        guard let filter = filter else { return nil }
        let index = orderedFilters.index(of: filter)
        return (index != NSNotFound ? orderedFilters.object(at: index) : filter) as? CIFilter
    }
    
    var ciFilter: CIFilterGroup {
        return CIFilterGroup(filters: orderedFilters.array as? [CIFilter])
    }
}

class CIFilterGroup: CIFilter {
    fileprivate(set) var filters: [CIFilter] = [CIFilter]()
    
    init(filters: [CIFilter]? = nil) {
        super.init()
        
        self.filters.append(contentsOf: filters ?? [])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        
        guard var image = value(forKey: kCIInputImageKey) as? CIImage else { return nil }
        
        for filter in filters {
            filter.setValue(image, forKey: kCIInputImageKey)
            if let result = filter.outputImage {
                image = result
            }
        }
        
        return image
    }
}

extension AdjustmentsApp {
    struct Adjustments {
        enum Name: String {
            case Brightness = "Brightness"
            case Contrast = "Contrast"
            case Highlights = "Highlights"
            case Shadows = "Shadows"
            case Saturation = "Saturation"
            case Vibrance = "Vibrance"
            case Temparature = "Temparature"
            case Tint = "Tint"
            case Fade = "Fade"
            case Grain = "Grain"
            case Vignette = "Vignette"
            case VignetteRadius = "Vignette Radius"
            case Sharpness = "Sharpness"
            
            var aliasName: String {
                return Adjustments.aliasName(self)
            }
            
            var builtInFilterName: String {
                return Adjustments.filterName(self)
            }
            
            var builtInParameterKey: String {
                return Adjustments.parameterKey(self)
            }
            
            var filter: CIFilter? {
                return Adjustments.filter(self)
            }
        }
        
        static func aliasName(_ name: Adjustments.Name) -> String {
            switch name {
            case Name.Brightness: return "Brightness".localized
            case Name.Contrast: return "Contrast".localized
            case Name.Highlights: return "Highlights".localized
            case Name.Shadows: return "Shadows".localized
            case Name.Saturation: return "Saturation".localized
            case Name.Vibrance: return "Vibrance".localized
            case Name.Temparature: return "Temparature".localized
            case Name.Tint: return "Tint".localized
            case Name.Fade: return "Fade".localized
            case Name.Grain: return "Grain".localized
            case Name.Vignette: return "Vignette".localized
            case Name.VignetteRadius: return "Vignette Radius".localized
            case Name.Sharpness: return "Sharpness".localized
            }
        }
        
        static func filterName(_ name: Adjustments.Name) -> String {
            switch name {
            case Name.Brightness, Name.Contrast, Name.Saturation: return "CIColorControls"
            case Name.Highlights, Name.Shadows: return "CIHighlightShadowAdjust"
            case Name.Vibrance: return "CIVibrance"
            case Name.Temparature, Name.Tint: return "CITemperatureAndTint"
            case Name.Fade: return "Fade"
            case Name.Grain: return "Grain"
            case Name.Vignette, Name.VignetteRadius: return "CIVignette"
            case Name.Sharpness: return "Sharpness"
            }
        }
        
        static func parameterKey(_ name: Adjustments.Name) -> String {
            switch name {
            case Name.Brightness: return kCIInputBrightnessKey
            case Name.Contrast: return kCIInputContrastKey
            case Name.Highlights: return "inputHighlightAmount"
            case Name.Shadows: return "inputShadowAmount"
            case Name.Saturation: return kCIInputSaturationKey
            case Name.Vibrance: return "inputAmount"
            case Name.Temparature: return ""
            case Name.Tint: return ""
            case Name.Fade: return ""
            case Name.Grain: return ""
            case Name.Vignette: return kCIInputIntensityKey
            case Name.VignetteRadius: return kCIInputRadiusKey
            case Name.Sharpness: return ""
            }
        }
        
        static func filter(_ name: Adjustments.Name) -> CIFilter? {
            switch name {
            case Name.Brightness,
                 Name.Contrast,
                 Name.Highlights,
                 Name.Shadows,
                 Name.Saturation,
                 Name.Vibrance,
                 Name.Vignette, Name.VignetteRadius:
                return CIBuiltInFilter(adjustmentName: name, adjustments: [AdjustmentValue(key: name.builtInParameterKey)])
            case Name.Temparature: return nil
            case Name.Tint: return nil
            case Name.Fade: return nil
            case Name.Grain: return nil
            case Name.Sharpness: return nil
            }
        }
    }
    
    static let AdjustmentsNames = [
        AdjustmentsApp.Adjustments.Name.Brightness,
        AdjustmentsApp.Adjustments.Name.Contrast,
        AdjustmentsApp.Adjustments.Name.Highlights,
        AdjustmentsApp.Adjustments.Name.Shadows,
        AdjustmentsApp.Adjustments.Name.Saturation,
        AdjustmentsApp.Adjustments.Name.Vibrance,
        AdjustmentsApp.Adjustments.Name.Temparature,
        AdjustmentsApp.Adjustments.Name.Tint,
//        AdjustmentsApp.Adjustments.Name.Fade,
//        AdjustmentsApp.Adjustments.Name.Grain,
        AdjustmentsApp.Adjustments.Name.Vignette,
        AdjustmentsApp.Adjustments.Name.VignetteRadius,
//        AdjustmentsApp.Adjustments.Name.Sharpness
    ]
}

private class _AdjustmentsAppTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _AdjustmentsAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _FiltersAppAsset)?.cancelAllRequestIDs()
        (param as? _FiltersAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _AdjustmentsAppAsset, "TaskParamable type of this app is \(_FiltersAppAsset.self)")
        guard let _param = param as? _AdjustmentsAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _AdjustmentsAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
//                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: AdjustmentsApp.self, editInfo: (assetItem.editState.ciFilter as? CIAdjustmentsFilter)?.filters.compactMap({ ["filter": $0.name] }) ?? [:], from: asset)
                    
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
 AdjustmentsAppDockContent
 */
import PropertyKit
private protocol AdjustmentsAppDefaults: AppDefaults{
    var adjustments: [String: Double] {get set}
}

extension Defaults: AdjustmentsAppDefaults {
    fileprivate var adjustments: [String: Double] {
        set{ set(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get{ return get(or: AdjustmentsApp.AdjustmentsNames.dictionary { ($0.rawValue, 0) } ) }
    }
}

class AdjustmentsAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    fileprivate static var primaryColor = AdjustmentsApp.info.themeColor
    fileprivate var adjustmentNames = AdjustmentsApp.AdjustmentsNames
    
    lazy var view: UIView = {
        let view = UITableView(frame: .zero)
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 52
        view.allowsSelection = false
        view.register(Cell.self, forCellReuseIdentifier: AdjustmentsApp.info.identifier)
        view.backgroundColor = .clear
        view.separatorStyle = .none
        return view
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
        preferences.preferredHeight = tableView.rowHeight * min(CGFloat(adjustmentNames.count), 4.5)
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        
        (view as? UITableView)?.reloadData()
    }
    
    @objc dynamic var filter: CIFilterGroup?
    
    private var filterItem = CIAdjustmentsFilterItem()
    
    func setFilterValues(_ filter: CIFilterGroup?, animated: Bool = true) {
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adjustmentNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AdjustmentsApp.info.identifier) as! Cell
        let filterName = adjustmentNames[indexPath.row]
        
        let filter = self.filterItem.adjustmentFilter(with: filterName.filter) as? CIBuiltInFilter
        
        cell.titleLabel.text = AdjustmentsApp.Adjustments.aliasName(filterName)
        
        if let adjustmentValue = filter?.adjustmentValue(forKey: filterName.builtInParameterKey) {
            cell.slider.minimumValue = adjustmentValue.minimumValue ?? 0
            cell.slider.maximumValue = adjustmentValue.maximumValue ?? 0
            cell.slider.setValue(adjustmentValue.value ?? 0, animated: false)
        }
        
        cell.sliderValueDidChange = { value in
            self.filterItem.setAdjustmentFilter(filter)
            (self.filterItem.adjustmentFilter(with: filter) as? CIBuiltInFilter)?.setAdjustmentValue(value, forKey: filterName.builtInParameterKey)
            
            Timer.scheduledTimer(identifier: #function, withTimeInterval: 0.2) { timer in
                DispatchQueue.main.asyncAfter(deadline: .now()){
                    self.filter = self.filterItem.ciFilter
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private class Cell: UITableViewCell {
        lazy var slider: UISlider = {
            let view = UISlider()
            view.addTarget(self, action: #selector(self.cellSliderValueDidChange), for: .valueChanged)
            return view
        }()
        
        lazy var titleLabel: UILabel = {
            let label = UILabel(frame: .zero)
            label.font = UIFont.systemFont(ofSize: 12)
            label.textAlignment = .right
            label.backgroundColor = UIColor.clear
            label.adjustsFontForContentSizeCategory = true
            return label
        }()
        
        var sliderValueDidChange: ((Float) -> Void)?
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
            sliderValueDidChange = nil
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            backgroundColor = .clear
            
            contentView.addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25).isActive = true
            
            contentView.addSubview(slider)
            slider.translatesAutoresizingMaskIntoConstraints = false
            slider.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            slider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            slider.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20).isActive = true
            contentView.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 20).isActive = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc func cellSliderValueDidChange(sender: UISlider) {
            sliderValueDidChange?(sender.value)
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
            
            titleLabel.textColor = tintColor
            slider.tintColor = tintColor
        }
    }
}
