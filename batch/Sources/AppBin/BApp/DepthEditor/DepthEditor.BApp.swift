//
//  DepthEditor.BApp.swift
//  batch
//
//  Created by HYOJIN MO on 26/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

class _DepthEditorAppAsset: _FiltersAppAsset {}

public class DepthEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {
    
    public static let taskType: AppTaskable.Type = _DepthEditorAppTask.self
    public static let paramType: AppTaskParamable.Type = _DepthEditorAppAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = DepthEditorAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = DepthEditorAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
//        var defaults = type(of: self).defaults as! DepthEditorAppDefaults
        
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
        identifier: "com.stells.batch.deptheditor"
        , version: "1.0"
        , phase: .develop
        , appType: DepthEditorApp.self
        , displayName: "DepthEditor".localized.localizedCapitalized
        , description: "DepthEditor lets you edit manually your photos.".localized
        , keywords: ["adjustments", "brightness", "constrast", "highlight", "shadow", "saturate", "vibrance"]
        , iconBundleName: nil
        , themeColor: UIColor(red:1, green:0.964, blue:0, alpha:1)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        let controllerContent = self.content as? DepthEditorAppDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
                
            } else {
//                var defaults = type(of: self).defaults as! DepthEditorAppDefaults
//                controllerContent?.options = defaults.autoAdjustmentOptions
//
//                let filter = CIAdjustmentFilter(options: defaults.autoAdjustmentOptions)
//                let filterItem = CIFilterItem(filter)
//                self.config?.filter = filterItem
//                self.defaultEditStateValue = filterItem
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? DepthEditorAppDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
                
            } else{
//                var defaults = type(of: self).defaults as! DepthEditorAppDefaults
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
        return [.actions]
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
        (content as? DepthEditorAppDockContent)?.setFilterValues(filter, animated: false)
    }
}

class DepthEditItem {
    class SliderValue {
        var name: DepthEditorApp.DepthEditor.Name
        var value: Float = 0
        var defaultValue: Float = 0
        var minimumValue: Float = 0
        var maximumValue: Float = 0
        
        init(name: DepthEditorApp.DepthEditor.Name, defaultValue: Float?, minimumValue: Float?, maximumValue: Float?) {
            self.name = name
            self.defaultValue = defaultValue ?? 0
            self.minimumValue = minimumValue ?? 0
            self.maximumValue = maximumValue ?? 0
            
            self.value = defaultValue ?? 0
        }
    }
    
    var key: String
    var value: Any {
        switch attributeType {
        case kCIAttributeTypeScalar?: return number
        case kCIAttributeTypeOffset?: return CIVector(cgPoint: offset)
        default: return number
        }
    }
    var number: Float {
        return sliderValue(at: 0)?.value ?? 0
    }
    var offset: CGPoint {
        return CGPoint(x: CGFloat(sliderValue(at: 0)?.value ?? 0), y: CGFloat(sliderValue(at: 1)?.value ?? 0))
    }
    
    private(set) var sliderValues: [SliderValue] = [SliderValue]()
    
    func sliderValue(at offsetIndex: Int) -> SliderValue? {
        return sliderValues[safe: offsetIndex]
    }
    
    func setSliderValue(_ value: Float, at offsetIndex: Int) {
        sliderValues[safe: offsetIndex]?.value = value
    }
    
    private var attributeType: String?
    private var attributeClass: AnyClass?
    
    init(key: String) {
        self.key = key
    }
    
    func setDefaults(with filter: CIFilter?, name: DepthEditorApp.DepthEditor.Name?) {
        guard let name = name, let attributes = filter?.attributes[key] as? [String: Any] else { return }
        
        attributeType = attributes[kCIAttributeType] as? String
        attributeClass = NSClassFromString(attributes[kCIAttributeClass] as? String ?? "")
        
        if attributeType == kCIAttributeTypeScalar, attributeClass == NSNumber.self {
            switch filter?.name {
            case "CISepiaTone"?:
                sliderValues = [SliderValue(name: name, defaultValue: 0, minimumValue: attributes[kCIAttributeSliderMin] as? Float, maximumValue: attributes[kCIAttributeSliderMax] as? Float)]
            default:
                sliderValues = [SliderValue(name: name, defaultValue: attributes[kCIAttributeDefault] as? Float, minimumValue: attributes[kCIAttributeSliderMin] as? Float, maximumValue: attributes[kCIAttributeSliderMax] as? Float)]
            }
        }
        else if attributeType == kCIAttributeTypeOffset, attributeClass == CIVector.self {
            switch filter?.name {
            case "CITemperatureAndTint"?:
                sliderValues = [
                    SliderValue(name: .Temparature, defaultValue: 6500, minimumValue: 2000, maximumValue: 10000),
                    SliderValue(name: .Tint, defaultValue: 0, minimumValue: -200, maximumValue: 200)
                ]
            default: break
            }
        }
    }
}

fileprivate class CIAdjustmentFilter: CIFilter {
    private(set) var adjustmentItems = [String: DepthEditItem]()
    private var builtInFilter: CIFilter?
    
    var filter: CIFilter {
        return builtInFilter ?? self
    }
    
    init(adjustmentName: DepthEditorApp.DepthEditor.Name) {
        super.init()
        
        self.name = adjustmentName.builtInFilterName
        self.builtInFilter = CIFilter(name: name)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return (name == (object as? CIFilter)?.name) == true
    }
    
    func adjustmentItem(with adjustmentName: DepthEditorApp.DepthEditor.Name) -> DepthEditItem? {
        let key = adjustmentName.builtInParameterKey
        guard let value = adjustmentItems[key] else {
            let adjustmentValue = DepthEditItem(key: key)
            adjustmentValue.setDefaults(with: self.filter, name: adjustmentName)
            adjustmentItems[key] = adjustmentValue
            return adjustmentValue
        }
        return value
    }
    
    func setAdjustmentValue(_ value: Float, with adjustmentName: DepthEditorApp.DepthEditor.Name) {
        adjustmentItem(with: adjustmentName)?.setSliderValue(value, at: adjustmentName.builtInParameterOffsetIndex)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        guard let image = value(forKey: kCIInputImageKey) as? CIImage else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        adjustmentItems.forEach { filter.setValue($0.value.value, forKey: $0.value.key) }
        return filter.outputImage
    }
}

fileprivate class CIFadeFilter: CIAdjustmentFilter {
    convenience init() {
        self.init(adjustmentName: .Fade)
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
    
    private lazy var kernel: CIColorKernel? = {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else { return nil }
        return try? CIColorKernel(functionName: "fade", fromMetalLibraryData: data)
    }()
    
    override var outputImage: CIImage? {
        guard let image = value(forKey: kCIInputImageKey) as? CIImage else { return nil }
        let params = adjustmentItems.compactMap { $0.value.number }
        return kernel?.apply(extent: image.extent, arguments: [image] + params)
    }
}

class CIDepthEditorFilterItem {
    private var orderedFilters = NSMutableOrderedSet()
    
    func setAdjustmentFilter(_ filter: CIFilter?) {
        guard let filter = filter, !orderedFilters.contains(filter) else { return }
        orderedFilters.add(filter)
    }
    
    fileprivate func adjustmentFilter(with filter: CIFilter?) -> CIAdjustmentFilter? {
        guard let filter = filter else { return nil }
        let index = orderedFilters.index(of: filter)
        return (index != NSNotFound ? orderedFilters.object(at: index) : filter) as? CIAdjustmentFilter
    }

    fileprivate var ciFilter: CIFilterGroup {
        return CIFilterGroup(filters: orderedFilters.array as? [CIFilter])
    }
    
    func reset() {
        orderedFilters.removeAllObjects()
    }
    
    func setAdjustmentFilters(_ filters: [CIFilter]?) {
        orderedFilters = NSMutableOrderedSet(array: filters ?? [])
    }
}

fileprivate class CIFilterGroup: CIFilter {
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

extension DepthEditorApp {
    struct DepthEditor {
        enum Name: String {
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
            case Sharpness = "Sharpness"
            case Fade = "Fade"
            case Grain = "Grain"
            
            var displayName: String {
                return DepthEditor.displayName(self)
            }
            
            var builtInFilterName: String {
                return DepthEditor.filterName(self)
            }
            
            var builtInParameterKey: String {
                return DepthEditor.parameterKey(self)
            }

            fileprivate var filter: CIAdjustmentFilter? {
                return DepthEditor.filter(self)
            }
            
            var builtInParameterOffsetIndex: Int {
                switch self {
                case .Temparature: return 0
                case .Tint: return 1
                default: return 0
                }
            }
        }

        fileprivate static func displayName(_ name: DepthEditor.Name) -> String {
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
            case Name.Fade: return "Fade".localized
            case Name.Grain: return "Grain".localized
            case Name.Vignette: return "Vignette".localized
            case Name.VignetteRadius: return "Vignette Radius".localized
            case Name.Sharpness: return "Sharpness".localized
            case Name.SepiaTone: return "Sepia Tone".localized
            }
        }
        
        static func filterName(_ name: DepthEditor.Name) -> String {
            switch name {
            case Name.Brightness, Name.Contrast, Name.Saturation: return "CIColorControls"
            case Name.Highlights, Name.Shadows: return "CIHighlightShadowAdjust"
            case Name.Vibrance: return "CIVibrance"
            case Name.Temparature, Name.Tint: return "CITemperatureAndTint"
            case Name.Gamma: return "CIGammaAdjust"
            case Name.Exposure: return "CIExposureAdjust"
            case Name.Fade: return "Fade"
            case Name.Grain: return "Grain"
            case Name.Vignette, Name.VignetteRadius: return "CIVignette"
            case Name.Sharpness: return "Sharpness"
            case Name.SepiaTone: return "CISepiaTone"
            }
        }
        
        static func parameterKey(_ name: DepthEditor.Name) -> String {
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
            case Name.Fade: return kCIInputIntensityKey
            case Name.Grain: return ""
            case Name.Vignette: return kCIInputIntensityKey
            case Name.VignetteRadius: return kCIInputRadiusKey
            case Name.Sharpness: return ""
            case Name.SepiaTone: return kCIInputIntensityKey
            }
        }
        
        fileprivate static func filter(_ name: DepthEditor.Name) -> CIAdjustmentFilter? {
            switch name {
            case Name.Brightness,
                 Name.Contrast,
                 Name.Highlights,
                 Name.Shadows,
                 Name.Saturation,
                 Name.Vibrance,
                 Name.Vignette, Name.VignetteRadius,
                 Name.Gamma,
                 Name.Exposure,
                 Name.Temparature, Name.Tint,
                 Name.SepiaTone:
                return CIAdjustmentFilter(adjustmentName: name)
            case Name.Fade: return CIFadeFilter()
            case Name.Grain: return nil
            case Name.Sharpness: return nil
            }
        }
    }
    
    static let DepthEditorNames = [
        DepthEditorApp.DepthEditor.Name.Brightness,
        DepthEditorApp.DepthEditor.Name.Exposure,
        DepthEditorApp.DepthEditor.Name.Contrast,
        DepthEditorApp.DepthEditor.Name.Highlights,
        DepthEditorApp.DepthEditor.Name.Shadows,
        DepthEditorApp.DepthEditor.Name.Saturation,
        DepthEditorApp.DepthEditor.Name.Vibrance,
        DepthEditorApp.DepthEditor.Name.Temparature,
        DepthEditorApp.DepthEditor.Name.Tint,
        DepthEditorApp.DepthEditor.Name.Fade,
//        DepthEditorApp.DepthEditor.Name.Grain,
        DepthEditorApp.DepthEditor.Name.Vignette,
        DepthEditorApp.DepthEditor.Name.VignetteRadius,
        DepthEditorApp.DepthEditor.Name.Gamma,
        DepthEditorApp.DepthEditor.Name.SepiaTone,
//        DepthEditorApp.DepthEditor.Name.Sharpness
    ]
}

fileprivate class _DepthEditorAppTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _DepthEditorAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _DepthEditorAppAsset)?.cancelAllRequestIDs()
        (param as? _DepthEditorAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _DepthEditorAppAsset, "TaskParamable type of this app is \(_DepthEditorAppAsset.self)")
        guard let _param = param as? _DepthEditorAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _DepthEditorAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
//                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: DepthEditorApp.self, editInfo: (assetItem.editState.ciFilter as? CIDepthEditorFilter)?.filters.compactMap({ ["filter": $0.name] }) ?? [:], from: asset)
                    
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
 DepthEditorAppDockContent
 */
import PropertyKit
private protocol DepthEditorAppDefaults: AppDefaults{
    var adjustments: [String: Double] {get set}
}

extension Defaults: DepthEditorAppDefaults {
    fileprivate var adjustments: [String: Double] {
        set{ set(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get{ return get(or: DepthEditorApp.DepthEditorNames.dictionary { ($0.rawValue, 0) } ) }
    }
}

class DepthEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    fileprivate static var primaryColor = DepthEditorApp.info.themeColor
    fileprivate var adjustmentNames = DepthEditorApp.DepthEditorNames
    fileprivate var adjustmentFilters = [CIAdjustmentFilter]()
    
    lazy var view: UIView = {
        let view = UITableView(frame: .zero)
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 52
        view.allowsSelection = false
        view.register(Cell.self, forCellReuseIdentifier: DepthEditorApp.info.identifier)
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
        
        installFilters()
        
        (view as? UITableView)?.reloadData()
    }
    
    private func installFilters(with filters: [CIFilter]? = nil) {
        adjustmentFilters = adjustmentNames.compactMap { $0.filter }.setable
        for adjustmentFilter in adjustmentFilters {
            guard let filter = (filters as? [CIAdjustmentFilter])?.first(where: { $0.name == adjustmentFilter.name }) else { continue }
            for adjustmentItem in filter.adjustmentItems.values {
                for sliderValue in adjustmentItem.sliderValues {
                    adjustmentFilter.setAdjustmentValue(sliderValue.value, with: sliderValue.name)
                }
            }
        }
    }

    @objc fileprivate dynamic var filter: CIFilterGroup?
    
    private var filterItem = CIDepthEditorFilterItem()

    fileprivate func setFilterValues(_ filter: CIFilterGroup?, animated: Bool = true) {
        guard let tableView = view as? UITableView else { return }
        
        self.filterItem.reset()
        self.filterItem.setAdjustmentFilters(filter?.filters)
        self.installFilters(with: filter?.filters)
        
        DispatchQueue.main.async {
            self.filter = self.filterItem.ciFilter
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adjustmentNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DepthEditorApp.info.identifier) as! Cell
        let filterName = adjustmentNames[indexPath.row]
        
        let filter = self.adjustmentFilters.first { $0.name == filterName.builtInFilterName }
        
        cell.titleLabel.text = filterName.displayName
        
        if let adjustmentItem = filter?.adjustmentItem(with: filterName) {
            cell.slider.minimumValue = adjustmentItem.sliderValue(at: filterName.builtInParameterOffsetIndex)?.minimumValue ?? 0
            cell.slider.maximumValue = adjustmentItem.sliderValue(at: filterName.builtInParameterOffsetIndex)?.maximumValue ?? 0
            cell.slider.defaultValue = adjustmentItem.sliderValue(at: filterName.builtInParameterOffsetIndex)?.defaultValue ?? 0
            cell.slider.setValue(adjustmentItem.sliderValue(at: filterName.builtInParameterOffsetIndex)?.value ?? 0, animated: false)
        }
        
        cell.sliderDidChangeHandler = { value in
            self.filterItem.setAdjustmentFilter(filter)
            self.filterItem.adjustmentFilter(with: filter)?.setAdjustmentValue(value, with: filterName)
            
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
        lazy var slider: PrecisionLevelSlider = {
            let view = PrecisionLevelSlider()
            view.longNotchColor = .white
            view.shortNotchColor = UIColor.init(white: 0.5, alpha: 1)
            view.centerNotchColor = .red
            view.numberOfNotches = 20
            return view
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
        
        var sliderDidChangeHandler: ((Float) -> Void)?
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
            sliderDidChangeHandler = nil
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
            
            contentView.addSubview(slider)
            slider.translatesAutoresizingMaskIntoConstraints = false
            slider.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            contentView.bottomAnchor.constraint(equalTo: slider.bottomAnchor, constant: 0).isActive = true
            slider.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20).isActive = true
            contentView.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 20).isActive = true
            
            slider.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        }
        
        @objc private func sliderValueChanged() {
            sliderDidChangeHandler?(slider.value)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
            
            titleLabel.textColor = tintColor
            slider.tintColor = tintColor
        }
    }
}

// PrecisionLevelSlider.swift
//
// Copyright (c) 2016 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import UIKit

fileprivate class PrecisionLevelSlider: UIControl {
    
    // MARK: - Properties
    open var longNotchColor: UIColor = .black {
        didSet {
            update()
        }
    }
    
    open var shortNotchColor: UIColor = UIColor(white: 0.2, alpha: 1) {
        didSet {
            update()
        }
    }
    
    open var centerNotchColor: UIColor = UIColor.orange {
        didSet {
            update()
        }
    }
    
    open var numberOfNotches: Int = 30 {
        didSet {
            update()
        }
    }
    
    /// default 0.0. this value will be pinned to min/max
    @objc dynamic open var value: Float = 0 {
        didSet {
            
            guard !scrollView.isDecelerating && !scrollView.isDragging else {
                return
            }
            
            setValue(value, animated: true)
        }
    }
    
    open func setValue(_ value: Float, animated: Bool) {
        let offset = valueToOffset(value: value)
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                
                self.scrollView.setContentOffset(offset, animated: false)
                
            }) { (finish) in
            }
        }
        else {
            self.scrollView.setContentOffset(offset, animated: false)
        }
    }
    
    /// default 0.0. the current value may change if outside new min value
    @objc dynamic open var minimumValue: Float = 0 {
        didSet {
            
        }
    }
    
    /// default 1.0. the current value may change if outside new max value
    @objc dynamic open var maximumValue: Float = 1 {
        didSet {
            
        }
    }
    
    @objc dynamic open var defaultValue: Float = 0 {
        didSet {
            defaultValueMark.position.x = valueToOffset(value: defaultValue).x + scrollView.contentInset.left
            defaultValueMark.position.y = 8
        }
    }
    
    open var isContinuous: Bool = true
    
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    
    private lazy var defaultValueMark: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        let markSize: CGFloat = 6
        layer.path = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: -markSize / 2, y: -markSize / 2), size: CGSize(width: markSize, height: markSize))).cgPath
        layer.actions = ["position": NSNull()]
        
        return layer
    }()
    private lazy var centerNotchLayer = CALayer()
    
    private lazy var gradientLayer: CAGradientLayer = {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        gradientLayer.locations = [0, 0.4, 0.6, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        
        return gradientLayer
    }()
    
    
    // MARK: - Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: - Functions
    open override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }
    
    func update() {
        
        let offset = valueToOffset(value: value)
        scrollView.setContentOffset(offset, animated: false)
        
        gradientLayer.frame = bounds
        let notchWidth: CGFloat = 1
        
        let interval = floor((bounds.size.width) / CGFloat(numberOfNotches))
        
        let longNotchHeight: CGFloat = 10
        let shortNotchHeight: CGFloat = 8
        let offsetY = bounds.height / 2
        
        let notchLayers: [CALayer] = {
            return (0...numberOfNotches).map { _ -> CALayer in
                CALayer()
            }
        }()
        
        notchLayers.enumerated().forEach { i, l in
            
            let x: CGFloat = CGFloat(i) * interval
            
            if i % 5 == 0 {
                l.backgroundColor = longNotchColor.cgColor
                
                l.frame = CGRect(
                    x: x,
                    y: offsetY - (longNotchHeight / 2),
                    width: notchWidth,
                    height: longNotchHeight)
                
            } else {
                l.backgroundColor = shortNotchColor.cgColor
                l.frame = CGRect(
                    x: x,
                    y: offsetY - (shortNotchHeight / 2),
                    width: notchWidth,
                    height: shortNotchHeight)
            }
        }
        
        contentView.layer.sublayers = notchLayers
        contentView.layer.addSublayer(defaultValueMark)
        
        defaultValueMark.fillColor = shortNotchColor.cgColor
        
        centerNotchLayer.backgroundColor = centerNotchColor.cgColor
        centerNotchLayer.frame = CGRect(x: bounds.midX, y: 0, width: notchWidth, height: bounds.height)
        
        let contentSize = CGSize(
            width: notchLayers.last!.frame.maxX - notchWidth,
            height: bounds.height
        )
        
        contentView.frame.size = contentSize
        scrollView.contentSize = contentSize
        
        let inset = contentSize.width / 2 + (max(0, scrollView.bounds.width - contentSize.width) / 2)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        
    }
    
    func setup() {
        
        layer.mask = gradientLayer
        
        backgroundColor = UIColor.clear
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        
        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        layer.addSublayer(centerNotchLayer)
    }
    
    fileprivate func offsetToValue() -> Float {
        return value(with: scrollView.contentOffset)
    }
    
    fileprivate func value(with offset: CGPoint) -> Float {
        let progress = (offset.x + scrollView.contentInset.left) / contentView.bounds.size.width
        let actualProgress = Float(min(max(0, progress), 1))
        let value = ((maximumValue - minimumValue) * actualProgress) + minimumValue
        
        return value
    }
    
    fileprivate func valueToOffset(value: Float) -> CGPoint {
        
        let progress = (value - minimumValue) / (maximumValue - minimumValue)
        let x = contentView.bounds.size.width * CGFloat(progress) - scrollView.contentInset.left
        return CGPoint(x: x, y: 0)
    }
    
    private var needsStickToDefaultValue: Bool = false {
        didSet {
            if needsStickToDefaultValue {
                if oldValue == false {
                    UIFeedback.select()
                    
                    stickTouchLocation = scrollView.panGestureRecognizer.location(in: self)
                    
                    defaultValueMark.isHidden = true
                }
                else {
                    defaultValueMark.isHidden = false
                }

                value = defaultValue
                setValue(defaultValue, animated: false)
                sendActions(for: .valueChanged)
            }
            else {
                defaultValueMark.isHidden = false
            }
        }
    }
    private var stickTouchLocation: CGPoint = .zero
    private var beginningScrollPosition: CGPoint = .zero
    private var previousScrollPosition: CGPoint = .zero
    
    var exponentialValue: Float {
//        let easeInExpo = CubicBezier(controlPoints: 0.95, 0.05, 0.795, 0.035)
        
        let size = CGSize(width: scrollView.contentSize.width / 2, height: bounds.size.height)
        let easeInExpo = CubicBezier(from: .zero, controlPoint1: CGPoint(x: size.width * 0.95, y: size.height * 0.05), controlPoint2: CGPoint(x: size.width * 0.795, y: size.height * 0.35), to: CGPoint(x: size.width, y: size.height))
        
        let t = (value - minimumValue) / (maximumValue - minimumValue)
        
        print(#function, t, easeInExpo.point(at: CGFloat(t)))
        
        return value(with: CGPoint(x: easeInExpo.y(at: CGFloat(t)), y: 0))
        
//        let actualProgress = Float(min(max(0, easeInExpo.y(at: CGFloat(t))), 1))
//        return ((maximumValue - minimumValue) * actualProgress) + minimumValue
    }
}

fileprivate struct CubicBezier {
    // http://www.paulwrightapps.com/blog/2014/9/4/finding-the-position-and-angle-of-points-along-a-bezier-curve-on-ios
    
    // cubic bezier control points
    private(set) var c0 = CGPoint.zero
    private(set) var c1 = CGPoint.zero
    private(set) var c2 = CGPoint.zero
    private(set) var c3 = CGPoint.zero
    
    // cubic bezier polynomial coefficients
    var p0: CGPoint {
        let x = c3.x - 3 * c2.x + 3 * c1.x - c0.x
        let y = c3.y - 3 * c2.y + 3 * c1.y - c0.y
        return CGPoint(x: x, y: y)
    }
    var p1: CGPoint {
        let x = 3 * c2.x - 6 * c1.x + 3 * c0.x
        let y = 3 * c2.y - 6 * c1.y + 3 * c0.y
        return CGPoint(x: x, y: y)
    }
    var p2: CGPoint {
        let x = 3 * c2.x - 6 * c1.x + 3 * c0.x
        let y = 3 * c2.y - 6 * c1.y + 3 * c0.y
        return CGPoint(x: x, y: y)
    }
    var p3: CGPoint {
        return c0
    }
    
    init(from c0: CGPoint, controlPoint1 c1: CGPoint, controlPoint2 c2: CGPoint, to c3: CGPoint) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
    }
    
    init(controlPoints c1: CGPoint, _ c2: CGPoint) {
        self.init(from: .zero, controlPoint1: c1, controlPoint2: c2, to: CGPoint(x: 1, y: 1))
    }
    
    init(controlPoints c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat) {
        self.init(controlPoints: CGPoint(x: c1x, y: c1y), CGPoint(x: c2x, y: c2y))
    }
    
    func x(at t: CGFloat) -> CGFloat {
        return ((p0.x * t + p1.x) * t + p2.x) * t + p3.x
    }
    
    func y(at t: CGFloat) -> CGFloat {
        return ((p0.y * t + p1.y) * t + p2.y) * t + p3.y
    }
    
    func point(at t: CGFloat) -> CGPoint {
        return CGPoint(x: x(at: t), y: y(at: t))
    }
    
    func angle(at t: CGFloat) -> CGFloat {
        let dxdt = 3 * p0.x * t * t + 2 * p1.x * t + p2.x
        let dydt = 3 * p0.y * t * t + 2 * p1.y * t + p2.y
        return atan2(dydt, dxdt)
    }
}

extension PrecisionLevelSlider {
    enum Direction {
        case none
        case left
        case right
    }
    
    private var stickTouchDifference: CGFloat {
        return scrollView.panGestureRecognizer.location(in: self).x - stickTouchLocation.x
    }
    
    private var scrollOffsetDifference: CGFloat {
        return scrollView.contentOffset.x - beginningScrollPosition.x
    }
    
    private var scrollDirection: Direction {
        return scrollOffsetDifference == 0 ? .none : (scrollOffsetDifference < 0 ? .left : .right)
    }
    
    private var sliderDifference: CGFloat {
        return scrollView.contentOffset.x - previousScrollPosition.x
    }
    
    private var sliderDirection: Direction {
        return sliderDifference == 0 ? .none : (sliderDifference < 0 ? .left : .right)
    }
    
    private var defaultValueOffsetDifference: CGFloat {
        return scrollView.contentOffset.x - valueToOffset(value: defaultValue).x
    }
    
    private var directionFromDefault: Direction {
        return defaultValueOffsetDifference == 0 ? .none : (defaultValueOffsetDifference < 0 ? .left : .right)
    }
}

extension PrecisionLevelSlider: UIScrollViewDelegate {
    public final func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginningScrollPosition = scrollView.contentOffset
        previousScrollPosition = scrollView.contentOffset
    }
    
    public final func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else {
            return
        }
        
        guard scrollView.isDecelerating || scrollView.isDragging else {
            return
        }
        
        if isContinuous {
            if needsStickToDefaultValue, stickTouchDifference.magnitude < 8 {
                scrollView.contentOffset = valueToOffset(value: defaultValue)
                value = defaultValue
            }
            else {
                value = offsetToValue()
                
                needsStickToDefaultValue = (scrollView.isTracking && sliderDirection != directionFromDefault && defaultValueOffsetDifference.magnitude < 8)
            }
            
            sendActions(for: .valueChanged)
            
            previousScrollPosition = scrollView.contentOffset
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isContinuous == false {
            value = offsetToValue()
            sendActions(for: .valueChanged)
        }
        defaultValueMark.isHidden = false
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
}
