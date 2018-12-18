//
//  RawEditorApp.swift
//  pap
//
//  Created by HYOJIN MO on 14/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit
import Photos

class _RawEditorAsset: _FiltersAppAsset {}

public class RawEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp {
    
    public static let taskType: AppTaskable.Type = _RawEditorTask.self
    public static let paramType: AppTaskParamable.Type = _RawEditorAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = RawEditorDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = RawEditorDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.raweditor"
        , version: "1.0"
        , phase: .develop
        , appType: RawEditorApp.self
        , displayName: "RAW Editor".localized.localizedCapitalized
        , description: "Edit your raw photos.".localized
        , keywords: ["raw", "dng", "adjustments", "brightness", "constrast", "highlight", "shadow", "saturate"]
        , iconBundleName: nil
        , themeColor: UIColor(red:0.5, green:0.964, blue:0, alpha:1)
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        let controllerContent = self.content as? RawEditorDockContent
        controllerContent?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContent?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? RawEditorDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
        }
    }
    
    public var doneButtonTitle: String? {
        return "Apply".localized
    }
    
    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.imageType == .stillImage && item.asset.hasRawImage
    }
    
    public var numberOfItemsShouldSelect: Int? {
        return 1
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
    
    private var cachedURL: URL?
    private func urlForRawImage(with asset: PHAsset) -> URL {
        return FileURL.temp(asset.localIdentifierWithoutSplitter, nil, group: FileURL.fileAndQueuePrivateGroup()).appendingPathExtension("dng")
    }
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
        
        let rawURL = urlForRawImage(with: appAsset.asset)
        
        if self.cachedURL != rawURL {
            guard let rawData = appAsset.asset.asRawData else {
                completion(original, nil)
                return
            }
            
            if let _ = try? rawData.write(to: rawURL) {
                self.cachedURL = rawURL
            }
        }
        
        let filtered = autoreleasepool { () -> UIImage? in
            let rawFilter = CIFilter(imageURL: rawURL, options: nil)
            rawFilter?.setValuesForKeys(appAsset.editState.ciFilter?.attributes ?? [:])
            let rawImage = rawFilter?.outputImage
            
            let jpgURL = FileURL.temp(appAsset.asset.localIdentifierWithoutSplitter, UTI.jpeg, group: FileURL.fileAndQueuePrivateGroup())
            rawImage?.writeJPEGRepresentation(to: jpgURL)
            
            return UIImage(contentsOfFile: jpgURL.path)?.resize(aspectFit: targetSize)
        }
        
        completion(original, filtered)
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        if let rawURL = self.cachedURL {
            setFilterToContent(CIFilter(imageURL: rawURL, options: nil))
        }
        else {
            setFilterToContent(editStateValue?.ciFilter)
        }
    }
    
    func didSelect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        DispatchQueue(label: RawEditorApp.info.identifier, qos: .utility).async  {
            let rawURL = self.urlForRawImage(with: asset)
            
            if self.cachedURL != rawURL {
                let rawData = asset.asRawData
                
                if let _ = try? rawData?.write(to: rawURL) {
                    self.cachedURL = rawURL
                }
            }
            
            self.setFilterToContent(CIFilter(imageURL: rawURL, options: nil))
        }
    }
    
    private func setFilterToContent(_ filter: CIFilter?) {
        var attributes = [String: Any]()
        filter?.inputKeys.forEach {
            if let v = filter?.value(forKey: $0) {
                attributes[$0] = v
            }
        }
        
        (self.content as? RawEditorDockContent)?.setDefaultRawAttributes(attributes)
    }
    
    func didDeselect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        self.cachedURL = nil
    }
}

fileprivate class _RawEditorTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _RawEditorAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _RawEditorAsset)?.cancelAllRequestIDs()
        (param as? _RawEditorAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _RawEditorAsset, "TaskParamable type of this app is \(_RawEditorAsset.self)")
        guard let _param = param as? _RawEditorAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _RawEditorAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    //                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: RawEditorApp.self, editInfo: (assetItem.editState.ciFilter as? CIAdjustmentsFilter)?.filters.compactMap({ ["filter": $0.name] }) ?? [:], from: asset)
                    
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
 RawEditorDockContent
 */
import PropertyKit
private protocol RawEditorDefaults: AppDefaults{
    
}

extension Defaults: RawEditorDefaults {
    
}

fileprivate class CIRawFilter: CIFilter {
    var rawAttributes: [CIRAWFilterOption: Any]?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(attributes rawAttributes: [CIRAWFilterOption: Any]?) {
        super.init()
        
        self.rawAttributes = rawAttributes
    }
    
    private var parameters: [String : Any]?
    override var attributes: [String : Any] {
        return parameters ?? [:]
    }
    
    init(parameters params: [String: Any]?) {
        super.init()
        
        self.parameters = params
    }
}

fileprivate class RawEditorDockContent: NSObject, PropertyWatchable, AppDockContent, UITableViewDelegate, UITableViewDataSource{
    fileprivate static var primaryColor = RawEditorApp.info.themeColor
    
    fileprivate var filterAttributes = [CIFilterAttributes]()
    
    lazy var view: UIView = {
        let view = UITableView(frame: .zero)
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 52
        view.allowsSelection = false
        view.register(SliderCell.self, forCellReuseIdentifier: RawEditorApp.info.identifier + "SliderCell")
        view.register(SwitchCell.self, forCellReuseIdentifier: RawEditorApp.info.identifier + "SwitchCell")
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
        preferences.preferredHeight = tableView.rowHeight * 4.5
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        
        if filterAttributes.isEmpty {
            installFilters()
        }
        
        (view as? UITableView)?.reloadData()
    }
    
    fileprivate func setDefaultRawAttributes(_ attributes: [String: Any]?) {
        installFilters()
        
        for filterAttribute in filterAttributes {
            if let defaultKey = attributes?.keys.first(where: { $0 == filterAttribute.key }) {
                if let value = attributes?[defaultKey] as? NSNumber {
                    let attributeItem = filterAttribute.attributes(at: 0)
                    attributeItem?.defaultValue = value.floatValue
                    attributeItem?.value = value.floatValue
                }
            }
        }
        
        DispatchQueue.main.async {
            (self.view as? UITableView)?.reloadData()
        }
    }
    
    private func rawAttributes() -> [CIFilterAttributes] {
        // https://developer.apple.com/documentation/coreimage/cifilter/raw_image_options
        return [
            CIFilterAttributes(key: CIRAWFilterOption.neutralTemperature.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Temperature".localized, defaultValue: 2000, minimumValue: 2000, maximumValue: 20000)]),
            CIFilterAttributes(key: CIRAWFilterOption.neutralTint.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Tint".localized, defaultValue: 0, minimumValue: -150, maximumValue: 150)]),
            CIFilterAttributes(key: CIRAWFilterOption.baselineExposure.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Baseline Exposure".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: "inputEV", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "EV".localized, defaultValue: 0, minimumValue: -3, maximumValue: 3)]),
            CIFilterAttributes(key: "inputBias", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Bias".localized, defaultValue: 0, minimumValue: -3, maximumValue: 25)]),
            CIFilterAttributes(key: CIRAWFilterOption.enableSharpening.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Sharpening".localized, boolValue: true)]),
//            CIFilterAttributes(key: CIRAWFilterOption.allowDraftMode.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Draft Mode", boolValue: false)]),
//            CIFilterAttributes(key: CIRAWFilterOption.neutralLocation.rawValue, attributeType: kCIAttributeTypePosition, attributes: [CIFilterAttributeItem(name: "NeutralLocationX", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 0), CIFilterAttributeItem(name: "NeutralLocationY", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 1)]), // no min max
            CIFilterAttributes(key: CIRAWFilterOption.enableVendorLensCorrection.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Vendor Lens Correction".localized, boolValue: true)]),
            CIFilterAttributes(key: CIRAWFilterOption.disableGamutMap.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Disable Gamut Map".localized, boolValue: false)]),
            CIFilterAttributes(key: CIRAWFilterOption.boostAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Boost".localized, defaultValue: 1, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.boostShadowAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Boost Shadow".localized, defaultValue: 0, minimumValue: 0, maximumValue: 2)]),
            CIFilterAttributes(key: CIRAWFilterOption.enableChromaticNoiseTracking.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Noise Tracking".localized, boolValue: true)]),
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no default
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionDetailAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction Detail".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.colorNoiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Color Noise Reduction".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionContrastAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction Contrast".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionSharpnessAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction Sharpness".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.luminanceNoiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Luminance Noise Reduction".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.neutralChromaticityX.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Chromaticity X".localized, defaultValue: 0.5, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: CIRAWFilterOption.neutralChromaticityY.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Chromaticity Y".localized, defaultValue: 0.5, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: CIRAWFilterOption.moireAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Moire".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: "inputHueMagMR", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagMR".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: "inputHueMagBM", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagBM".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: "inputHueMagYG", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagYG".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: "inputHueMagCB", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagCB".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: "inputHueMagRY", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagRY".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: "inputHueMagGC", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagGC".localized, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: CIRAWFilterOption.scaleFactor.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Scale Factor", defaultValue: 1, minimumValue: 0, maximumValue: 1)]),
        ]
    }
    
    private func installFilters(with filters: [CIFilter]? = nil) {
        filterAttributes = rawAttributes()
    }
    
    @objc dynamic var filter: CIFilter?
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return filterAttributes.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let filterAttribute = filterAttributes[section]
        return filterAttribute.attributeItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let filterAttribute = filterAttributes[indexPath.section]
        let attributeItem = filterAttribute.attributeItems[indexPath.row]
        
        if filterAttribute.attributeType == kCIAttributeTypeBoolean, let cell = tableView.dequeueReusableCell(withIdentifier: RawEditorApp.info.identifier + "SwitchCell") as? SwitchCell {
            cell.titleLabel.text = attributeItem.name
            
            cell.switchControl.setOn(attributeItem.value == 1.0 ? true : false, animated: true)
            
            cell.switchDidChangeHandler = { isOn in
                attributeItem.value = isOn ? 1.0 : 0.0
                
                Timer.scheduledTimer(identifier: #function, withTimeInterval: 0.2) { timer in
                    DispatchQueue.main.asyncAfter(deadline: .now()){
                        self.filter = CIRawFilter(parameters: Dictionary(uniqueKeysWithValues: self.filterAttributes.map({ ($0.key, $0.value) })))
                    }
                }
            }
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: RawEditorApp.info.identifier + "SliderCell") as! SliderCell
            cell.titleLabel.text = attributeItem.name
            
            cell.slider.minimumValue = attributeItem.minimumValue
            cell.slider.maximumValue = attributeItem.maximumValue
            cell.slider.defaultValue = attributeItem.defaultValue
            cell.slider.setValue(attributeItem.value, animated: true)
            
            cell.sliderDidChangeHandler = { value in
                attributeItem.value = value
                
                Timer.scheduledTimer(identifier: #function, withTimeInterval: 0.2) { timer in
                    DispatchQueue.main.asyncAfter(deadline: .now()){
                        self.filter = CIRawFilter(parameters: Dictionary(uniqueKeysWithValues: self.filterAttributes.map({ ($0.key, $0.value) })))
                    }
                }
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private class SliderCell: UITableViewCell {
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
            sliderDidChangeHandler?(slider.bezierValue)
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
    
    private class SwitchCell: UITableViewCell {
        lazy var switchControl: UISwitch = {
            let view = UISwitch(frame: .zero)
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
        
        var switchDidChangeHandler: ((Bool) -> Void)?
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
            switchDidChangeHandler = nil
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
            
            let componentView = UIView(frame: .zero)
            contentView.addSubview(componentView)
            componentView.translatesAutoresizingMaskIntoConstraints = false
            componentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
            contentView.bottomAnchor.constraint(equalTo: componentView.bottomAnchor, constant: 0).isActive = true
            componentView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 20).isActive = true
            contentView.trailingAnchor.constraint(equalTo: componentView.trailingAnchor, constant: 20).isActive = true
            
            componentView.addSubview(switchControl)
            switchControl.translatesAutoresizingMaskIntoConstraints = false
            switchControl.centerXAnchor.constraint(equalTo: componentView.centerXAnchor).isActive = true
            switchControl.centerYAnchor.constraint(equalTo: componentView.centerYAnchor).isActive = true
            
            switchControl.addTarget(self, action: #selector(self.switchValueChanged), for: .valueChanged)
        }
        
        @objc private func switchValueChanged() {
            switchDidChangeHandler?(switchControl.isOn)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func tintColorDidChange() {
            super.tintColorDidChange()
            
            titleLabel.textColor = tintColor
            switchControl.thumbTintColor = tintColor
            switchControl.onTintColor = RawEditorApp.info.themeColor ?? tintColor
        }
    }
}
