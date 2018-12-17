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
        
//        var defaults = type(of: self).defaults as! RawEditorDefaults

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
                
            } else {
//                var defaults = type(of: self).defaults as! RawEditorDefaults
//                controllerContent?.options = defaults.autoAdjustmentOptions
//
//                let filter = CIAdjustmentFilter(options: defaults.autoAdjustmentOptions)
//                let filterItem = CIFilterItem(filter)
//                self.config?.filter = filterItem
//                self.defaultEditStateValue = filterItem
            }
        }
        
        let controllerContentInPhotoEditor = self.photoEditorDockContent as? RawEditorDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
                
            } else{
//                var defaults = type(of: self).defaults as! RawEditorDefaults
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
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        DispatchQueue(label: #file + ".editRawImage", qos: .utility).async {
            let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
            
            let rawURL = FileURL.temp(appAsset.asset.localIdentifierWithoutSplitter, nil, group: FileURL.fileAndQueuePrivateGroup()).appendingPathExtension("dng")
            
            if self.cachedURL != rawURL {
                let async = AsyncSignal()
                async.begin()
                
                guard
                    let rawAsset = appAsset.asset.resources.first(where: { $0.type == .alternatePhoto })
                    else {
                        async.end()
                        completion(original, nil)
                        return
                }
                
                DispatchQueue(label: #file + ".fetchRawImage", qos: .utility).async {
                    var rawData = Data()
                    
                    let options = PHAssetResourceRequestOptions()
                    options.isNetworkAccessAllowed = true
                    PHAssetResourceManager.default().requestData(for: rawAsset, options: options, dataReceivedHandler: { (data) in
                        rawData.append(data)
                    }, completionHandler: { (error) in
                        guard error == nil else {
                            async.end()
                            completion(original, nil)
                            return
                        }
                        
                        if let _ = try? rawData.write(to: rawURL) {
                            self.cachedURL = rawURL
                        }
                        
                        async.end()
                    })
                }
                async.waitUntilEnd()
            }
            
            let rawAttributes = (appAsset.editState.ciFilter as? CIRawFilter)?.rawAttributes ?? [:]
            let rawFilter = CIFilter(imageURL: rawURL, options: rawAttributes)
            completion(original, rawFilter?.outputImage?.asUIImage)
        }
        
//        let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
//        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
//        completion(original, filtered)
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        let filter = editStateValue?.ciFilter
//        (content as? RawEditorDockContent)?.setFilterValues(filter, animated: false)
    }
    
    func didSelect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        
    }
    
    func didDeselect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        
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
        view.register(Cell.self, forCellReuseIdentifier: RawEditorApp.info.identifier)
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
        
        installFilters()
        
        (view as? UITableView)?.reloadData()
    }
    
    private func rawAttributes() -> [CIFilterAttributes] {
        return [
//            CIFilterAttributes(key: CIRAWFilterOption.neutralChromaticityX.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NeutralChromaticityX", defaultValue: 0.5, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: CIRAWFilterOption.enableSharpening.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "EnableSharpening", boolValue: true)]),
//            CIFilterAttributes(key: CIRAWFilterOption.allowDraftMode.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "DraftMode", boolValue: false)]),
//            CIFilterAttributes(key: CIRAWFilterOption.neutralLocation.rawValue, attributeType: kCIAttributeTypePosition, attributes: [CIFilterAttributeItem(name: "x", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 0), CIFilterAttributeItem(name: "y", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 1)]), // no min max
//            CIFilterAttributes(key: "inputHueMagMR", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagMR", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NoiseReductionAmount", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no default
//            CIFilterAttributes(key: CIRAWFilterOption.enableVendorLensCorrection.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "EnableVendorLensCorrection", defaultValue: 1, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: "inputHueMagCB", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagCB", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: CIRAWFilterOption.colorNoiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "ColorNoiseReductionAmount", defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionContrastAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NoiseReductionContrastAmount", defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: CIRAWFilterOption.disableGamutMap.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "DisableGamutMap", boolValue: false)]),
//            CIFilterAttributes(key: CIRAWFilterOption.boostAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Boost", defaultValue: 1, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.neutralTint.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NeutralTint", defaultValue: 0, minimumValue: -150, maximumValue: 150)]),
//            CIFilterAttributes(key: "inputHueMagRY", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagRY", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: CIRAWFilterOption.enableChromaticNoiseTracking.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "EnableNoiseTracking", boolValue: true)]),
//            CIFilterAttributes(key: CIRAWFilterOption.boostShadowAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "BoostShadowAmount", defaultValue: 0, minimumValue: 0, maximumValue: 2)]),
//            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionSharpnessAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NoiseReductionSharpnessAmount", defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: "inputHueMagBM", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagBM", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: "inputHueMagYG", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagYG", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
//            CIFilterAttributes(key: "inputBias", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Bias", defaultValue: 0, minimumValue: -3, maximumValue: 25)]),
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionDetailAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NoiseReductionDetailAmount", defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: CIRAWFilterOption.baselineExposure.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "BaselineExposure", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: CIRAWFilterOption.neutralTemperature.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NeutralTemperature", defaultValue: 2000, minimumValue: 2000, maximumValue: 20000)]),
//            CIFilterAttributes(key: CIRAWFilterOption.luminanceNoiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "LuminanceNoiseReductionAmount", defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: CIRAWFilterOption.neutralChromaticityY.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "NeutralChromaticityY", defaultValue: 0.5, minimumValue: 0, maximumValue: 1)]), // no min max
            CIFilterAttributes(key: "inputEV", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "EV", defaultValue: 0, minimumValue: -3, maximumValue: 3)]),
//            CIFilterAttributes(key: CIRAWFilterOption.moireAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "MoireAmount", defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: CIRAWFilterOption.scaleFactor.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Scale Factor", defaultValue: 1, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: "inputHueMagGC", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "HueMagGC", defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no min max
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
        let cell = tableView.dequeueReusableCell(withIdentifier: RawEditorApp.info.identifier) as! Cell
        
        let filterAttribute = filterAttributes[indexPath.section]
        let attributeItem = filterAttribute.attributeItems[indexPath.row]
        
        cell.titleLabel.text = attributeItem.name.localized
        
        cell.slider.minimumValue = attributeItem.minimumValue
        cell.slider.maximumValue = attributeItem.maximumValue
        cell.slider.defaultValue = attributeItem.defaultValue
        cell.slider.value = attributeItem.value
        
        cell.sliderDidChangeHandler = { value in
            attributeItem.value = value
            
            Timer.scheduledTimer(identifier: #function, withTimeInterval: 0.2) { timer in
                DispatchQueue.main.asyncAfter(deadline: .now()){
                    self.filter = CIRawFilter(attributes: Dictionary(uniqueKeysWithValues: self.filterAttributes.map({ (CIRAWFilterOption(rawValue: $0.key), $0.value) })))
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
}
