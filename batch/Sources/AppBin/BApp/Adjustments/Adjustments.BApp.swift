//
//  Adjustments.BApp.swift
//  batch
//
//  Created by HYOJIN MO on 26/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

protocol CIAdjustmentFilterDataSource {
    associatedtype Name
    static func displayName(of name: Name) -> String
    static func key(of name: Name) -> String
    static func attributeIndex(of name: Name) -> Int
    static func filterName(of name: Name) -> String
}

fileprivate struct Adjustments: CIAdjustmentFilterDataSource {
    enum Name: String, CaseIterable {
        case Brightness = "Brightness"
        case Contrast = "Contrast"
        case Highlights = "Highlights"
        case Shadows = "Shadows"
        case Saturation = "Saturation"
        case Vibrance = "Vibrance"
        case Temparature = "Temparature"
        case Tint = "Tint"
        case Vignette = "Vignette"
        case VignetteRadius = "Vignette Radius"
        case Gamma = "Gamma"
        case Exposure = "Exposure"
        case SepiaTone = "SepiaTone"
        case Fade = "Fade"
        case Sharpness = "Sharpness"
        
        var key: String {
            return Adjustments.key(of: self)
        }
        
        var displayName: String {
            return Adjustments.displayName(of: self)
        }
        
        var attributeIndex: Int {
            return Adjustments.attributeIndex(of: self)
        }
        
        var filterName: String {
            return Adjustments.filterName(of: self)
        }
    }
    
    static func displayName(of name: Name) -> String {
        switch name {
        case Name.Brightness: return "Brightness".localized
        case Name.Contrast: return "Contrast".localized
        case Name.Highlights: return "Highlights".localized
        case Name.Shadows: return "Shadows".localized
        case Name.Saturation: return "Saturation".localized
        case Name.Vibrance: return "Vibrance".localized
        case Name.Temparature: return "Temparature".localized
        case Name.Tint: return "Tint".localized
        case Name.Gamma: return "Gamma".localized
        case Name.Exposure: return "Exposure".localized
        case Name.Vignette: return "Vignette".localized
        case Name.VignetteRadius: return "Vignette Radius".localized
        case Name.SepiaTone: return "Sepia Tone".localized
        case Name.Fade: return "Fade".localized
        case Name.Sharpness: return "Sharpness".localized
        }
    }
    
    static func key(of name: Name) -> String {
        switch name {
        case Name.Brightness: return kCIInputBrightnessKey
        case Name.Contrast: return kCIInputContrastKey
        case Name.Highlights: return "inputHighlightAmount"
        case Name.Shadows: return "inputShadowAmount"
        case Name.Saturation: return kCIInputSaturationKey
        case Name.Vibrance: return "inputAmount"
        case Name.Temparature: return "inputNeutral"
        case Name.Tint: return "inputNeutral"
        case Name.Gamma: return "inputPower"
        case Name.Exposure: return "inputEV"
        case Name.Vignette: return kCIInputIntensityKey
        case Name.VignetteRadius: return kCIInputRadiusKey
        case Name.SepiaTone: return kCIInputIntensityKey
        case Name.Fade: return kCIInputIntensityKey
        case Name.Sharpness: return kCIInputSharpnessKey
        }
    }
    
    static func attributeIndex(of name: Name) -> Int {
        switch name {
        case Name.Temparature: return 0
        case Name.Tint: return 1
        default: return 0
        }
    }
    
    static func filterName(of name: Name) -> String {
        switch name {
        case Name.Brightness, Name.Contrast, Name.Saturation: return "CIColorControls"
        case Name.Highlights, Name.Shadows: return "CIHighlightShadowAdjust"
        case Name.Vibrance: return "CIVibrance"
        case Name.Temparature, Name.Tint: return "CITemperatureAndTint"
        case Name.Gamma: return "CIGammaAdjust"
        case Name.Exposure: return "CIExposureAdjust"
        case Name.Vignette, Name.VignetteRadius: return "CIVignette"
        case Name.SepiaTone: return "CISepiaTone"
        case Name.Fade: return "CIFadeFilter"
        case Name.Sharpness: return "CISharpenLuminance"
        }
    }
}

class _AdjustmentsAppAsset: _FiltersAppAsset {}

public class AdjustmentsApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, UndoableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {
    
    public static let taskType: AppTaskable.Type = _AdjustmentsAppTask.self
    public static let paramType: AppTaskParamable.Type = _AdjustmentsAppAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = AdjustmentsAppDockContent(app: self)
    public private(set) lazy var photoEditorDockContent: AppDockContent? = AdjustmentsAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        if var defaults = type(of: self).defaults as? AdjustmentsAppDefaults, let filter = editStateValue?.ciFilter as? CIAdjustmentFilterGroup {
            defaults.adjustments = filter.filterAttributes
        }
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.adjustments"
        , version: "1.0"
        , phase: .release
        , appType: AdjustmentsApp.self
        , displayName: "Adjustments".localized.localizedCapitalized
        , description: "Adjustments lets you edit your photos expertly with each property such as exposure intensity or vignette radius.".localized
        , keywords: ["Adjustments", "Light", "Color", "RGB"] + Adjustments.Name.allCases.map { $0.rawValue }
        , iconBundleName: R.image.adjustmentsBAppIcon.name
        , themeColor: UIColor(rgb: 0xFFF533)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        let controllerContent = self.content as? AdjustmentsAppDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? AdjustmentsAppDefaults {
                let filter = controllerContent?.preferredFilter(with: defaults.adjustments)
                
                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
                self.defaultEditStateValue = filterItem
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? AdjustmentsAppDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else if var defaults = type(of: self).defaults as? AdjustmentsAppDefaults {
                let filter = controllerContent?.preferredFilter(with: defaults.adjustments)
                
                let filterItem = CIFilterItem(filter)
                self.config?.filter = filterItem
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
        return [.actions]
    }
    
    public static var fixedContentLayout: Bool {
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
        if let filter = editStateValue?.ciFilter as? CIAdjustmentFilterGroup {
            (content as? AdjustmentsAppDockContent)?.setFilterValues(filter, animated: false)
            
            if self.undoStack.isEmpty {
                self.registerUndo(filter.filterAttributes)
            }
        }
    }
    
    public var undoStack: [[CIFilterAttributes]] = [[CIFilterAttributes]]()
    public var undoItemIndex: Int = 0
    
    public func undoItemIndexDidChange(_ item: Array<CIFilterAttributes>?) {
        var controller: AdjustmentsAppDockContent?
        if let content = self.content as? AdjustmentsAppDockContent {
            controller = content
        }
        else if let content = self.photoEditorDockContent as? AdjustmentsAppDockContent {
            controller = content
        }
        
        let filter = controller?.preferredFilter(with: item ?? [])
        controller?.setFilterValues(filter)
        
        self.config?.filter = CIFilterItem(filter)
    }
}

fileprivate extension CIAdjustmentSliderInfo {
    init(name: Adjustments.Name, range: ClosedRange<Float>? = nil, userAttributeItems: [CIFilterAttributeItem]? = nil) {
        self.init(name: name.rawValue, attributeKey: name.key, range: range, userAttributeItems: userAttributeItems)
    }
}

fileprivate extension CIAdjustmentFilter {
    convenience init(adjustment: Adjustments.Name, sliderInfo: [CIAdjustmentSliderInfo]) {
        self.init(name: adjustment.filterName, sliderInfo: sliderInfo)
    }
    
    private func adjustmentItem(with adjustmentName: Adjustments.Name) -> CIFilterAttributes? {
        return filterAttributes[adjustmentName.key]
    }
    
    func setAdjustmentValue(_ value: Float, with adjustmentName: Adjustments.Name) {
        adjustmentItem(with: adjustmentName)?.setAttributes(value: value, at: adjustmentName.attributeIndex)
    }
}

fileprivate class CIFadeFilter: CIAdjustmentFilter {
    convenience init(sliderInfo: [CIAdjustmentSliderInfo]) {
        self.init(name: "CIFadeFilter", sliderInfo: sliderInfo)
    }
    
    override var attributes: [String: Any] {
        return [
            kCIAttributeFilterDisplayName: "Fade",
            kCIInputImageKey: [
                kCIAttributeIdentity: 0,
                kCIAttributeClass: NSStringFromClass(CIImage.self),
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage
            ],
            kCIInputIntensityKey: [
                kCIAttributeIdentity: 0,
                kCIAttributeClass: NSStringFromClass(NSNumber.self),
                kCIAttributeDefault: Float(0),
                kCIAttributeDisplayName: "Intensity",
                kCIAttributeMin: Float(0),
                kCIAttributeMax: Float(1),
                kCIAttributeSliderMin: Float(0),
                kCIAttributeSliderMax: Float(1),
                kCIAttributeType: kCIAttributeTypeScalar
            ]
        ]
    }

    override var outputImage: CIImage? {
        return autoreleasepool { () -> CIImage? in
            guard let image = inputImage else { return nil }
            let params = filterAttributes.compactMap { $0.value.number }
            var uniformValues = [MTLBuffer]()
            for var value in params {
                guard let buffer = MTLContext.shared.device.makeBuffer(bytes: &value, length: MemoryLayout.size(ofValue: value), options: MTLResourceOptions.cpuCacheModeWriteCombined) else { continue }
                uniformValues.append(buffer)
            }
            return image.applyMetalShader(fragmentFunction: "fadeEffect", fragmentUniforms: uniformValues)
        }
    }
}

fileprivate class AdjustmentFilterManager {
    private static var orderedFilters: [CIAdjustmentFilter] {
        return [
            CIAdjustmentFilter(adjustment: .Temparature, sliderInfo: [CIAdjustmentSliderInfo(name: .Temparature, userAttributeItems: [CIFilterAttributeItem(name: Adjustments.Name.Temparature.rawValue, defaultValue: 6500, minimumValue: 2000, maximumValue: 10000), CIFilterAttributeItem(name: Adjustments.Name.Tint.rawValue, defaultValue: 0, minimumValue: -150, maximumValue: 150)]), CIAdjustmentSliderInfo(name: .Tint, userAttributeItems: [CIFilterAttributeItem(name: Adjustments.Name.Temparature.rawValue, defaultValue: 6500, minimumValue: 2000, maximumValue: 10000), CIFilterAttributeItem(name: Adjustments.Name.Tint.rawValue, defaultValue: 0, minimumValue: -150, maximumValue: 150)])]),
            CIAdjustmentFilter(adjustment: .Highlights, sliderInfo: [CIAdjustmentSliderInfo(name: .Highlights), CIAdjustmentSliderInfo(name: .Shadows)]),
            CIAdjustmentFilter(adjustment: .Exposure, sliderInfo: [CIAdjustmentSliderInfo(name: .Exposure, range: -2...2)]),
            CIAdjustmentFilter(adjustment: .Gamma, sliderInfo: [CIAdjustmentSliderInfo(name: .Gamma, range: 0.5...3)]),
            CIAdjustmentFilter(adjustment: .Vibrance, sliderInfo: [CIAdjustmentSliderInfo(name: .Vibrance)]),
            CIAdjustmentFilter(adjustment: .Brightness, sliderInfo: [CIAdjustmentSliderInfo(name: .Brightness, range: -0.2...0.2), CIAdjustmentSliderInfo(name: .Contrast, range: 0.7...1.5), CIAdjustmentSliderInfo(name: .Saturation)]),
            CIFadeFilter(sliderInfo: [CIAdjustmentSliderInfo(name: .Fade, range: 0...1)]),
            CIAdjustmentFilter(adjustment: .Vignette, sliderInfo: [CIAdjustmentSliderInfo(name: .Vignette), CIAdjustmentSliderInfo(name: .VignetteRadius)]),
            CIAdjustmentFilter(adjustment: .SepiaTone, sliderInfo: [CIAdjustmentSliderInfo(name: .SepiaTone, userAttributeItems: [CIFilterAttributeItem(name: Adjustments.Name.SepiaTone.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)])]),
            CIAdjustmentFilter(adjustment: .Sharpness, sliderInfo: [CIAdjustmentSliderInfo(name: .Sharpness)])
        ]
    }
    
    private(set) var filters: [CIAdjustmentFilter] = AdjustmentFilterManager.orderedFilters
    
    func filter(with name: String) -> CIAdjustmentFilter? {
        return filters.first { $0.name == name }
    }
    
    fileprivate var ciFilter: CIAdjustmentFilterGroup {
        return CIAdjustmentFilterGroup(filters: filters.filter({ $0.hasChanges }))
    }
    
    func setAdjustmentFilters(_ filters: [CIAdjustmentFilter]? = nil, filterAttributes: [CIFilterAttributes]? = nil) {
        self.filters = []
        for filter in AdjustmentFilterManager.orderedFilters {
            let filter = filters?.first(where: { $0.name == filter.name }) ?? filter
            self.filters.append(filter)
            
            for adjustmentItem in filter.filterAttributes {
                let attributes = filterAttributes?.first(where: { $0.name == adjustmentItem.value.name }) ?? adjustmentItem.value
                for attributeItem in attributes.attributeItems {
                    if let name = Adjustments.Name(rawValue: attributeItem.name) {
                        filter.setAdjustmentValue(attributeItem.value, with: name)
                    }
                }
            }
        }
    }
}

fileprivate class CIAdjustmentFilterGroup: CIFilterGroup<CIAdjustmentFilter> {
    var filterAttributes: [CIFilterAttributes] {
        return filters.map { $0.filterAttributes.values }.reduce([], +)
    }
}

fileprivate class _AdjustmentsAppTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _AdjustmentsAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _AdjustmentsAppAsset)?.cancelAllRequestIDs()
        (param as? _AdjustmentsAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _AdjustmentsAppAsset, "TaskParamable type of this app is \(_AdjustmentsAppAsset.self)")
        guard let _param = param as? _AdjustmentsAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _AdjustmentsAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    let adjustments = (assetItem.editState.ciFilter as? CIAdjustmentFilterGroup)?.filters.map({ $0.filterAttributes.values }).reduce([], +) ?? []
                    
                    var editInfo: [String: Any] = [:]
                    if let jsonData = try? JSONEncoder().encode(adjustments), let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? Array<Any> {
                        editInfo["adjustments"] = json
                    }
                    
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: AdjustmentsApp.self, editInfo: editInfo, from: asset)
                    
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

/*
 AdjustmentsAppDockContent
 */
import PropertyKit
private protocol AdjustmentsAppDefaults: AppDefaults{
    var adjustments: [CIFilterAttributes] { get set }
}

extension Defaults: AdjustmentsAppDefaults {
    fileprivate var adjustments: [CIFilterAttributes] {
        set { set(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get { return get(or: []) }
    }
}

fileprivate class AdjustmentsAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    var app: AdjustmentsApp?
    
    fileprivate static var primaryColor = AdjustmentsApp.info.themeColor
    fileprivate lazy var orderedAdjustments: [Adjustments.Name] = [
        .Brightness,
        .Exposure,
        .Contrast,
        .Highlights,
        .Shadows,
        .Saturation,
        .Vibrance,
        .Temparature,
        .Tint,
        .Fade,
        .Vignette,
        .VignetteRadius,
        .Gamma,
        .SepiaTone,
        .Sharpness
    ]
    fileprivate var attributeItems = [CIFilterAttributeItem]()
    
    convenience init(app: AdjustmentsApp) {
        self.init()
        
        self.app = app
    }
    
    lazy var view: UIView = {
        let view = UITableView(frame: .zero)
        view.dataSource = self
        view.delegate = self
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 52
        view.allowsSelection = false
        view.register(CIAdjustmentSliderCell.self, forCellReuseIdentifier: AdjustmentsApp.info.identifier + "\(CIAdjustmentSliderCell.self)")
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
        preferences.preferredHeight = tableView.estimatedRowHeight * min(CGFloat(attributeItems.count), 4.5)
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        
        if attributeItems.isEmpty {
            installFilters()
        }
        
        (view as? UITableView)?.reloadData()
    }
    
    fileprivate func preferredFilter(with filterAttributes: [CIFilterAttributes]) -> CIAdjustmentFilterGroup? {
        let manager = AdjustmentFilterManager()
        manager.setAdjustmentFilters(nil, filterAttributes: filterAttributes)
        return manager.ciFilter
    }
    
    private func installFilters(with filters: [CIAdjustmentFilter]? = nil) {
        filterManager.setAdjustmentFilters(filters)
        attributeItems.removeAll()
        
        for adjustmentFilter in filterManager.filters {
            for adjustmentItem in adjustmentFilter.filterAttributes {
                for attributeItem in adjustmentItem.value.attributeItems {
                    guard let name = Adjustments.Name(rawValue: attributeItem.name), self.orderedAdjustments.contains(name) else { continue }
                    attributeItems.append(attributeItem)
                }
            }
        }
        
        attributeItems.sort {
            guard let adjustmentName1 = Adjustments.Name(rawValue: $0.name), let adjustmentName2 = Adjustments.Name(rawValue: $1.name) else { return false }
            return self.orderedAdjustments.firstIndex(of: adjustmentName1) ?? 0 < self.orderedAdjustments.firstIndex(of: adjustmentName2) ?? 0
        }
    }
    
    @objc dynamic var filter: CIFilter?
    
    private lazy var filterManager = AdjustmentFilterManager()
    
    func setFilterValues(_ filter: CIAdjustmentFilterGroup?, animated: Bool = true) {
        guard let tableView = view as? UITableView, let filter = filter?.copy() as? CIAdjustmentFilterGroup else { return }
        
        self.filterManager.setAdjustmentFilters(filter.filters)
        self.installFilters(with: filter.filters)
        
        DispatchQueue.main.async {
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributeItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attributeItem = attributeItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: AdjustmentsApp.info.identifier + "\(CIAdjustmentSliderCell.self)") as! CIAdjustmentSliderCell
        
        if let name = Adjustments.Name(rawValue: attributeItem.name) {
            cell.titleLabel.text = name.displayName
        }
        else {
            cell.titleLabel.text = attributeItem.name
        }
        
        cell.highlightedColor = AdjustmentsApp.info.themeColor
        
        cell.slider.minimumValue = attributeItem.minimumValue
        cell.slider.maximumValue = attributeItem.maximumValue
        cell.slider.defaultValue = attributeItem.defaultValue
        cell.slider.value = attributeItem.value
        
        cell.resetButton.isHidden = !attributeItem.hasChanges
        cell.resetButtonDidTapHandler = {
            attributeItem.value = attributeItem.defaultValue
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            cell.slider.value = attributeItem.value
            
            self.markAsSelectedFilterAttribiutes((self.filter as? CIAdjustmentFilterGroup)?.filterAttributes)
            self.filter = self.filterManager.ciFilter
        }
        
        cell.sliderDidChangeHandler = { value in
            attributeItem.value = value
            
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            DispatchQueue.main.async {
                self.filter = self.filterManager.ciFilter
            }
        }
        
        cell.sliderDidEndHandler = {
            let filter = self.filterManager.ciFilter
            self.markAsSelectedFilterAttribiutes(filter.filterAttributes)
            self.filter = filter
        }
        
        return cell
    }
    
    private func markAsSelectedFilterAttribiutes(_ filterAttributes: [CIFilterAttributes]?) {
        guard let filterAttributes = filterAttributes else { return }
        self.app?.registerUndo(filterAttributes.compactMap({ $0.copy() as? CIFilterAttributes }))
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

public class CIAdjustmentSliderCell: UITableViewCell {
    lazy var slider: PrecisionLevelSlider = {
        let view = PrecisionLevelSlider()
        view.longNotchColor = .white
        view.shortNotchColor = UIColor.init(white: 0.5, alpha: 1)
        view.centerNotchColor = highlightedColor ?? .red
        view.numberOfNotches = 20
        return view
    }()
    
    var highlightedColor: UIColor? {
        didSet {
            resetButton.setTitleColor(highlightedColor, for: .normal)
            slider.centerNotchColor = highlightedColor ?? .red
        }
    }
    
    lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("☀︎", for: .normal)
        button.setTitleColor(highlightedColor, for: .normal)
        return button
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.light)
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    lazy var iconView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var resetButtonDidTapHandler: (() -> Void)?
    var sliderDidBeginHandler: (() -> Void)?
    var sliderDidEndHandler: (() -> Void)?
    var sliderDidChangeHandler: ((Float) -> Void)?
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        
        resetButtonDidTapHandler = nil
        sliderDidChangeHandler = nil
        
        titleLabel.text = nil
        iconView.image = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25).isActive = true
        
        contentView.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        iconView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        iconView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 0).isActive = true
//        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
//        iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor, multiplier: 1).isActive = true
        
        contentView.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        contentView.bottomAnchor.constraint(equalTo: slider.bottomAnchor, constant: 0).isActive = true
        slider.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20).isActive = true
        contentView.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 20).isActive = true
        
        contentView.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 0).isActive = true
        resetButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: -2).isActive = true
        resetButton.isHidden = true
        
        resetButton.addTarget(self, action: #selector(self.resetButtonDidTap), for: .touchUpInside)
        slider.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(self.sliderDidBegin), for: .editingDidBegin)
        slider.addTarget(self, action: #selector(self.sliderDidEnd), for: .editingDidEnd)
    }
    
    @objc private func resetButtonDidTap() {
        UIFeedback.select()
        resetButtonDidTapHandler?()
    }
    
    @objc private func sliderDidBegin() {
        sliderDidBeginHandler?()
    }
    
    @objc private func sliderDidEnd() {
        sliderDidEndHandler?()
    }
    
    @objc private func sliderValueChanged() {
        sliderDidChangeHandler?(slider.value)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        
        titleLabel.textColor = tintColor
        slider.tintColor = tintColor
    }
}


import Intents

extension AdjustmentsApp:UIApplicationDelegateLaunchableApp{

    private static let Lomography = "Make the last item Lomography style".localized

    static var intents: [INIntent]{

        if #available(iOS 12.0, *) {
            return defaultIntents + [intentTo(do:Lomography)]

        } else{
            return []
        }

    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

        if #available(iOS 12.0, *) {
            guard let intent = userActivity.interaction?.intent else {
                return
            }

            if let i = intent as? DoAnyIntent{

                if i.doWhat == type(of: self).Lomography{
                    //TODO:Max Vinette -> 0 satura -> - half of exposure -> run
                }
            }
        }

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }
}

