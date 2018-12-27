//
//  Adjustments.BApp.swift
//  batch
//
//  Created by HYOJIN MO on 26/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit

private struct Adjustments {
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
    
    private static func displayName(of name: Name) -> String {
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
        }
    }
    
    private static func key(of name: Name) -> String {
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
        }
    }
    
    private static func attributeIndex(of name: Name) -> Int {
        switch name {
        case Name.Temparature: return 0
        case Name.Tint: return 1
        default: return 0
        }
    }
    
    private static func filterName(of name: Name) -> String {
        switch name {
        case Name.Brightness, Name.Contrast, Name.Saturation: return "CIColorControls"
        case Name.Highlights, Name.Shadows: return "CIHighlightShadowAdjust"
        case Name.Vibrance: return "CIVibrance"
        case Name.Temparature, Name.Tint: return "CITemperatureAndTint"
        case Name.Gamma: return "CIGammaAdjust"
        case Name.Exposure: return "CIExposureAdjust"
        case Name.Vignette, Name.VignetteRadius: return "CIVignette"
        case Name.SepiaTone: return "CISepiaTone"
        }
    }
}

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
        
        if var defaults = type(of: self).defaults as? AdjustmentsAppDefaults, let filter = editStateValue?.ciFilter as? CIFilterGroup, !filter.filterAttributes.isEmpty {
            defaults.adjustments = filter.filterAttributes
        }
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.adjustments"
        , version: "1.0"
        , phase: .develop
        , appType: AdjustmentsApp.self
        , displayName: "Adjustments".localized.localizedCapitalized
        , description: "Adjustments lets you edit manually your photos.".localized
        , keywords: ["adjustments", "brightness", "constrast", "highlight", "shadow", "saturation", "vibrance"]
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
            }
            else if var defaults = type(of: self).defaults as? AdjustmentsAppDefaults {
                controllerContent?.setPreferredFilterAttributes(defaults.adjustments)
                
                let filterItem = CIFilterItem(controllerContent?.preferredFilter)
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
                controllerContent?.setPreferredFilterAttributes(defaults.adjustments)
                
                let filterItem = CIFilterItem(controllerContent?.preferredFilter)
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
    public lazy var previewOriginalImageCache: NSCache<NSString, CIImage> = NSCache<NSString, CIImage>()
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let cacheKey = fileName() + appAsset.asset.localIdentifierWithoutSplitter + "\(targetSize)" as NSString
        
        let original = previewOriginalImageCache.object(forKey: cacheKey) ?? appAsset.asset.requestThumbnailImage(targetSize: targetSize)?.asCIImage
        
        if let image = original {
            previewOriginalImageCache.setObject(image, forKey: cacheKey)
        }
        
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original?.asUIImage, filtered?.asUIImage)
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        if let filter = editStateValue?.ciFilter as? CIFilterGroup {
            (content as? AdjustmentsAppDockContent)?.setFilterValues(filter, animated: false)
        }
    }
}

fileprivate class CIAdjustmentFilter: CIFilter {
    private(set) var adjustmentItems = [String: CIFilterAttributes]()
    private var builtInFilter: CIFilter?
    
    var filter: CIFilter {
        return builtInFilter ?? self
    }
    
    init(name: String, adjustments: [(name: Adjustments.Name, range: ClosedRange<Float>?)]) {
        super.init()
        
        self.name = name
        self.builtInFilter = CIFilter(name: name)
        self.adjustmentItems = [:]
        for adjustment in adjustments {
            let attributes = CIFilterAttributes(key: adjustment.name.key)
            attributes.setDefaults(with: filter, name: adjustment.name.rawValue, sliderRange: adjustment.range)
            adjustmentItems[adjustment.name.key] = attributes
        }
    }
    
    var hasChanges: Bool {
        return adjustmentItems.values.reduce(false) { $0 || $1.hasChanges }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return (name == (object as? CIFilter)?.name) == true
    }
    
    func adjustmentItem(with adjustmentName: Adjustments.Name) -> CIFilterAttributes? {
        return adjustmentItems[adjustmentName.key]
    }
    
    func setAdjustmentValue(_ value: Float, with adjustmentName: Adjustments.Name) {
        adjustmentItem(with: adjustmentName)?.setAttributes(value: value, at: adjustmentName.attributeIndex)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        return autoreleasepool { () -> CIImage? in
            guard let image = inputImage else { return nil }
            filter.setValue(image, forKey: kCIInputImageKey)
            adjustmentItems.forEach { filter.setValue($0.value.value, forKey: $0.value.key) }
            return filter.outputImage
        }
    }
}

//fileprivate class CIFadeFilter: CIAdjustmentFilter {
//    convenience init() {
//        self.init(adjustmentName: .Fade)
//    }
//
//    override var attributes: [String: Any] {
//        return [
//            kCIAttributeFilterDisplayName: "Fade",
//            kCIInputImageKey: [
//                kCIAttributeIdentity: 0,
//                kCIAttributeClass: NSStringFromClass(CIImage.self),
//                kCIAttributeDisplayName: "Image",
//                kCIAttributeType: kCIAttributeTypeImage
//            ],
//            kCIInputIntensityKey: [
//                kCIAttributeIdentity: 0,
//                kCIAttributeClass: NSStringFromClass(NSNumber.self),
//                kCIAttributeDefault: Float(0),
//                kCIAttributeDisplayName: "Intensity",
//                kCIAttributeMin: Float(0),
//                kCIAttributeMax: Float(1),
//                kCIAttributeSliderMin: Float(0),
//                kCIAttributeSliderMax: Float(1),
//                kCIAttributeType: kCIAttributeTypeScalar
//            ]
//        ]
//    }
//
//    private lazy var kernel: CIColorKernel? = {
//        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else { return nil }
//        return try? CIColorKernel(functionName: "fade", fromMetalLibraryData: data)
//    }()
//
//    override var outputImage: CIImage? {
//        guard let image = inputImage else { return nil }
//        let params = adjustmentItems.compactMap { $0.value.number }
//        return kernel?.apply(extent: image.extent, arguments: [image] + params)
//    }
//}

fileprivate class AdjustmentFilterManager {
    private static var orderedFilters: [CIAdjustmentFilter] {
        return [
            CIAdjustmentFilter(name: "CITemperatureAndTint", adjustments: [(name: .Temparature, range: nil), (name: .Tint, range: nil)]),
            CIAdjustmentFilter(name: "CIHighlightShadowAdjust", adjustments: [(name: .Highlights, range: nil), (name: .Shadows, range: nil)]),
            CIAdjustmentFilter(name: "CIExposureAdjust", adjustments: [(name: .Exposure, range: -2...2)]),
            CIAdjustmentFilter(name: "CIGammaAdjust", adjustments: [(name: .Gamma, range: 0.5...3)]),
            CIAdjustmentFilter(name: "CIVibrance", adjustments: [(name: .Vibrance, range: nil)]),
            CIAdjustmentFilter(name: "CIColorControls", adjustments: [(name: .Brightness, range: -0.2...0.2), (name: .Contrast, range: 0.7...1.5), (name: .Saturation, range: nil)]),
            CIAdjustmentFilter(name: "CIVignette", adjustments: [(name: .Vignette, range: nil), (name: .VignetteRadius, range: nil)]),
            CIAdjustmentFilter(name: "CISepiaTone", adjustments: [(name: .SepiaTone, range: nil)])
        ]
    }
    
    private(set) var filters: [CIAdjustmentFilter] = AdjustmentFilterManager.orderedFilters
    
    func filter(with name: String) -> CIAdjustmentFilter? {
        return filters.first { $0.name == name }
    }
    
    fileprivate var ciFilter: CIFilterGroup {
        return CIFilterGroup(filters: filters.filter({ $0.hasChanges }))
    }
    
    func setAdjustmentFilters(_ filters: [CIAdjustmentFilter]? = nil, filterAttributes: [CIFilterAttributes]? = nil) {
        self.filters = []
        for filter in AdjustmentFilterManager.orderedFilters {
            let filter = filters?.first(where: { $0.name == filter.name }) ?? filter
            self.filters.append(filter)
            
            for adjustmentItem in filter.adjustmentItems {
                let attributes = filterAttributes?.first(where: { $0.key == adjustmentItem.key }) ?? adjustmentItem.value
                for attributeItem in attributes.attributeItems {
                    if let name = Adjustments.Name(rawValue: attributeItem.name) {
                        filter.setAdjustmentValue(attributeItem.value, with: name)
                    }
                }
            }
        }
    }
    
    func reset() {
        filters = AdjustmentFilterManager.orderedFilters
    }
}

fileprivate class CIFilterGroup: CIFilter {
    fileprivate(set) var filters: [CIAdjustmentFilter] = [CIAdjustmentFilter]()
    
    init(filters: [CIAdjustmentFilter]? = nil) {
        super.init()
        
        self.filters.append(contentsOf: filters ?? [])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var filterAttributes: [CIFilterAttributes] {
        return filters.map { $0.adjustmentItems.values }.reduce([], +)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        
        guard var image = inputImage else { return nil }
        
        for filter in filters {
            autoreleasepool {
                filter.setValue(image, forKey: kCIInputImageKey)
                if let result = filter.outputImage {
                    image = result
                }
            }
        }
        
        return image
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
    var adjustments: [CIFilterAttributes] { get set }
}

extension Defaults: AdjustmentsAppDefaults {
    fileprivate var adjustments: [CIFilterAttributes] {
        set { set(newValue); print(newValue); papLog.app.defaults.log(value:String(describing: newValue)) }
        get { return get(or: []) }
    }
}

fileprivate class AdjustmentsAppDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
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
        .Vignette,
        .VignetteRadius,
        .Gamma,
        .SepiaTone
    ]
    fileprivate var attributeItems = [CIFilterAttributeItem]()
    
    lazy var view: UIView = {
        let view = UITableView(frame: .zero)
        view.dataSource = self
        view.delegate = self
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = 52
        view.allowsSelection = false
        view.register(Cell.self, forCellReuseIdentifier: AdjustmentsApp.info.identifier + "\(Cell.self)")
        view.register(ToneCurveCell.self, forCellReuseIdentifier: AdjustmentsApp.info.identifier + "\(ToneCurveCell.self)")
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
    
    private var preferredFilterAttributes: [CIFilterAttributes]?
    fileprivate func setPreferredFilterAttributes(_ attributes: [CIFilterAttributes]?) {
        preferredFilterAttributes = attributes
    }
    
    fileprivate var preferredFilter: CIFilterGroup? {
        let manager = AdjustmentFilterManager()
        manager.setAdjustmentFilters(nil, filterAttributes: preferredFilterAttributes)
        return manager.ciFilter
    }
    
    private func installFilters(with filters: [CIAdjustmentFilter]? = nil, filterAttributes: [CIFilterAttributes]? = nil) {
        filterManager.reset()
        filterManager.setAdjustmentFilters(filters, filterAttributes: filterAttributes)
        attributeItems.removeAll()
        
        for adjustmentFilter in filterManager.filters {
            for adjustmentItem in adjustmentFilter.adjustmentItems {
                for attributeItem in adjustmentItem.value.attributeItems {
                    attributeItems.append(attributeItem)
                }
            }
        }
        
        attributeItems.sort {
            guard let adjustmentName1 = Adjustments.Name(rawValue: $0.name), let adjustmentName2 = Adjustments.Name(rawValue: $1.name) else { return false }
            return self.orderedAdjustments.firstIndex(of: adjustmentName1) ?? 0 < self.orderedAdjustments.firstIndex(of: adjustmentName2) ?? 0
        }
    }
    
    @objc dynamic var filter: CIFilterGroup?
    
    private lazy var filterManager = AdjustmentFilterManager()
    
    func setFilterValues(_ filter: CIFilterGroup?, animated: Bool = true) {
        guard let tableView = view as? UITableView, let filters = filter?.filters else { return }
        
        self.filterManager.reset()
        self.filterManager.setAdjustmentFilters(filters)
        self.installFilters(with: filters)
        
        DispatchQueue.main.async {
            self.filter = self.filterManager.ciFilter
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
//        if filterName == .ToneCurve, let cell = tableView.dequeueReusableCell(withIdentifier: AdjustmentsApp.info.identifier + "\(ToneCurveCell.self)") as? ToneCurveCell {
//            cell.titleLabel.text = filterName.displayName
//            return cell
//        }
//        else {
        let cell = tableView.dequeueReusableCell(withIdentifier: AdjustmentsApp.info.identifier + "\(Cell.self)") as! Cell
        
        cell.titleLabel.text = attributeItem.name
        
        cell.slider.minimumValue = attributeItem.minimumValue
        cell.slider.maximumValue = attributeItem.maximumValue
        cell.slider.defaultValue = attributeItem.defaultValue
        cell.slider.value = attributeItem.value
        cell.resetButton.isHidden = !attributeItem.hasChanges
        
        cell.resetButtonDidTapHandler = {
            attributeItem.value = attributeItem.defaultValue
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            cell.slider.value = attributeItem.value
            
            self.filter = self.filterManager.ciFilter
        }
        
        cell.sliderDidChangeHandler = { value in
            attributeItem.value = value
            
            cell.resetButton.isHidden = !attributeItem.hasChanges
            
            let timer = Timer.scheduledTimer(identifier: #function, withTimeInterval: 0) { timer in
                DispatchQueue.main.async {
                    self.filter = self.filterManager.ciFilter
                }
            }
            RunLoop.current.add(timer, forMode: .common)
        }
        
        return cell
//        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private class Cell: UITableViewCell {
        lazy var slider: PrecisionLevelSlider = {
            let view = PrecisionLevelSlider()
            view.longNotchColor = .white
            view.shortNotchColor = UIColor.init(white: 0.5, alpha: 1)
            view.centerNotchColor = AdjustmentsApp.info.themeColor ?? .red
            view.numberOfNotches = 20
            return view
        }()
        
        lazy var resetButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("☀︎", for: .normal)
            button.setTitleColor(AdjustmentsApp.info.themeColor, for: .normal)
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
        
        var resetButtonDidTapHandler: (() -> Void)?
        var sliderDidChangeHandler: ((Float) -> Void)?
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
            resetButtonDidTapHandler = nil
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
            
            contentView.addSubview(resetButton)
            resetButton.translatesAutoresizingMaskIntoConstraints = false
            resetButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 0).isActive = true
            resetButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: -2).isActive = true
            resetButton.isHidden = true
            
            resetButton.addTarget(self, action: #selector(self.resetButtonDidTap), for: .touchUpInside)
            slider.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        }
        
        @objc private func resetButtonDidTap() {
            resetButtonDidTapHandler?()
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
    
    private class ToneCurveCell: UITableViewCell {
        lazy var slider: ToneCurveSlider = {
            let view = ToneCurveSlider(frame: .zero)
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
//            sliderDidChangeHandler?(slider.bezierValue)
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

private class ToneCurveSlider: UIControl {
    private var pointControls = [UIControl]()
    private var sliders = [PrecisionLevelSlider]()
    
//    private lazy var histogramView = UIView(frame: .zero)
    private lazy var controlView = UIView(frame: .zero)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        addSubview(controlView)
        controlView.fitConstraints(to: self)
        
        invalidateIntrinsicContentSize()
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.width * 1.5)
    }
}
