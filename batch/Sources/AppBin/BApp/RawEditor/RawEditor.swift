//
//  RawEditorApp.swift
//  pap
//
//  Created by HYOJIN MO on 14/12/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit
import Photos

class _RawEditorAsset: AppAsset {}

public class RawEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp, PhotoEditorViewControllerDelegatableApp, PhotoEditorPreviewProcessableApp {

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
        , phase: .release
        , appType: RawEditorApp.self
        , displayName: "RAW Editor".localized
        , description: "Edit your raw photos.".localized
        , keywords: ["raw", "dng", "Nikon", "Cannon", "Adobe", "LightRoom", "Editor"]
        , iconBundleName: R.image.rawEditorBAppIcon.name
        , themeColor: UIColor(rgb: 0xB4FF24)
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
            else {
                self.config?.filter = nil
            }
        }

        let controllerContentInPhotoEditor = self.photoEditorDockContent as? RawEditorDockContent
        controllerContentInPhotoEditor?.watch(\.filter, options: [.initial, .new]) {
            if let filter = controllerContentInPhotoEditor?.filter {
                self.config?.filter = CIFilterItem(filter)
            }
            else {
                self.config?.filter = nil
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

    private func urlForRawImage(with asset: PHAsset) -> URL {
        return FileURL.temp(asset.localIdentifierWithoutSplitter, nil, group: FileURL.fileAndQueuePrivateGroup()).appendingPathExtension("dng")
    }

    //INFO: prevent memory leak for creating CIImage(uiImage:)
    public lazy var previewOriginalImageCache: NSCache<NSString, CIImage>? = NSCache<NSString, CIImage>()
    private lazy var rawFilterCache: NSCache<NSString, CIFilter> = NSCache<NSString, CIFilter>()
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, in content: AppDockContent?, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        guard let rawFilter = loadRawFilter(with: appAsset.asset, in: content, asyncSignal: AsyncSignal()) else { return }

        rawFilter.setDefaults()

        //INFO: for preview
        rawFilter.setValue(true, forKey: CIRAWFilterOption.allowDraftMode.rawValue)
        rawFilter.setValue((UIScreen.main.bounds.size.minLength / appAsset.asset.pixelSize.maxLength) * UIScreen.main.scale, forKey: CIRAWFilterOption.scaleFactor.rawValue)

        let cacheKey = fileName() + appAsset.asset.localIdentifierWithoutSplitter as NSString

        var original: CIImage?
        if let image = previewOriginalImageCache?.object(forKey: cacheKey) {
            original = image
        }
        else if let image = rawFilter.outputImage {
            original = image
            previewOriginalImageCache?.setObject(image, forKey: cacheKey)
        }

        rawFilter.setValuesForKeys(appAsset.editState.ciFilter?.attributes ?? [:])

        completion(original?.asUIImage, rawFilter.outputImage?.asUIImage)
    }

    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        guard let content = content as? RawEditorDockContent else { return }

        if let rawFilter = editStateValue?.ciFilter as? CIRawFilter {
            setFilter(rawFilter, to: content)
        }
    }

    func didSelect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        resetFilter(in: self.content as? RawEditorDockContent)
    }

    private func loadRawFilter(with asset: PHAsset, in content: AppDockContent?, asyncSignal: AsyncWaitSignalable) -> CIFilter? {
        if let filter = self.rawFilterCache.object(forKey: asset.localIdentifier as NSString) {
            return filter
        }

        var ciFilter: CIFilter?

        asyncSignal.begin()
        rawFilterCache.removeAllObjects()
        rawFilter(from: asset) { (rawFilter) in
            self.setFilter(rawFilter, to: content as? RawEditorDockContent)

            if let imageURL = rawFilter?.rawURL, let filter = CIFilter(imageURL: imageURL, options: nil) {
                self.rawFilterCache.setObject(filter, forKey: asset.localIdentifier as NSString)

                ciFilter = filter

                DispatchQueue.main.async {
                    self.config?.filter = CIFilterItem(rawFilter)
                }
            }

            asyncSignal.end()
        }
        asyncSignal.waitUntilEnd()

        return ciFilter
    }

    private func rawFilter(from asset: PHAsset, completion: ((CIRawFilter?) -> Void)?) {
        DispatchQueue(label: RawEditorApp.info.identifier, qos: .background).async {
            let rawURL = self.urlForRawImage(with: asset)

            let rawData = asset.asRawData
            try? rawData?.write(to: rawURL)

            let rawFilter = CIRawFilter(rawURL: rawURL, params: nil)
            completion?(rawFilter)
        }
    }

    private func setFilter(_ filter: CIRawFilter?, to content: RawEditorDockContent?) {
        content?.setRawFilter(filter, attributes: filter?.attributes)
    }

    func didDeselect(asset: PHAsset, indexPath: IndexPath, callee: PhotoPickerViewControllerUniversalOperations) {
        resetFilter(in: self.content as? RawEditorDockContent)
    }

    func didDeselectAll(callee: PhotoPickerViewControllerUniversalOperations) {
        resetFilter(in: self.content as? RawEditorDockContent)
    }

    private func resetFilter(in content: RawEditorDockContent?) {
        rawFilterCache.removeAllObjects()
        setFilter(nil, to: content)
        self.defaultEditStateValue = nil
    }
}

extension _RawEditorAsset: PHAssetImageEditable {
    func edit<T: ImageProcessable>(processor: T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let asset = self.asset

        guard let ciImage = autoreleasepool(invoking: { () -> CIImage? in
            let filter = self.editState.ciFilter as? CIRawFilter

            let rawFilter = CIFilter(imageURL: filter?.rawURL, options: nil)
            if let attributes = filter?.attributes {
                rawFilter?.setValuesForKeys(attributes)
            }

            guard let ciImage = rawFilter?.outputImage else {
                completionHandler(nil, nil, nil)
                return nil
            }

            return ciImage
        }) else {
            completionHandler(nil, nil, nil)
            return nil
        }

        let jpegData = autoreleasepool { () -> Data? in
            //https://developer.apple.com/videos/play/wwdc2016/505/
            let contextForRawImageSaving = CIContext(options: [
                CIContextOption.cacheIntermediates: false,
                CIContextOption.priorityRequestLow: true
            ])

            return contextForRawImageSaving.jpegRepresentation(of: ciImage, colorSpace: ciImage.defaultColorSpace, options: [
                kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 1.0,
                kCGImageDestinationOptimizeColorForSharing as CIImageRepresentationOption: true
            ])
        }

        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil, nil, nil)
                return
            }

            DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
                autoreleasepool {
                    guard let _ = try? jpegData?.write(to: item.output.renderedContentURL) else {
                        completionHandler(nil, nil, nil)
                        return
                    }

                    completionHandler(asset, [PHAssetEditingResultItem(url: item.output.renderedContentURL, resourceType: .photo)], item.output)
                }
            }
        }
        return [PHAssetRequestID(forEditingInput: r)]
    }
}

fileprivate class _RawEditorTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _RawEditorAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){

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

        let rawFilter = assetItem.editState.ciFilter as? CIRawFilter

        let attributes = rawFilter?.attributes ?? [:]

        var editInfo: [String: Any] = [:]
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: []), let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? Array<Any> {
            editInfo["attributes"] = json
        }

        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: RawEditorApp.self, editInfo: editInfo, from: asset)

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
 RawEditorDockContent
 */
import PropertyKit
private protocol RawEditorDefaults: AppDefaults{

}

extension Defaults: RawEditorDefaults {

}

fileprivate class CIRawFilter: CIFilter {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private var parameters: [String : Any]?
    override public var attributes: [String : Any] {
        return parameters ?? [:]
    }

    private(set) var rawURL: URL?
    init(rawURL: URL?, params parameters: [String: Any]?) {
        super.init()

        self.rawURL = rawURL
        self.parameters = parameters
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
        view.register(CIAdjustmentSliderCell.self, forCellReuseIdentifier: RawEditorApp.info.identifier + "CIAdjustmentSliderCell")
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
        enabledEditing = false

        if filterAttributes.isEmpty {
            installFilters()
        }

        reloadFilter()
    }

    func willRemoveContentView() {
        self.filter = nil
    }

    private(set) var rawFilter: CIRawFilter?

    fileprivate func setRawFilter(_ rawFilter: CIRawFilter?, attributes: [String: Any]? = nil) {
        self.rawFilter = rawFilter

        var filter: CIFilter?
        if let imageURL = rawFilter?.rawURL {
            filter = CIFilter(imageURL: imageURL, options: nil)
        }

        var defaultAttributes = [String: Any]()
        filter?.inputKeys.forEach {
            if let v = filter?.value(forKey: $0) {
                defaultAttributes[$0] = v
            }
        }
        filterAttributes = []

        if let _ = filter {
            for filterAttribute in rawAttributes() {
                guard let defaultKey = defaultAttributes.keys.first(where: { $0 == filterAttribute.key }), let defaultValue = defaultAttributes[defaultKey] as? NSNumber else { continue }

                let attributeItem = filterAttribute.attributes(at: 0)
                attributeItem?.defaultValue = defaultValue.floatValue

                if let valueKey = attributes?.keys.first(where: { $0 == filterAttribute.key }), let value = attributes?[valueKey] as? NSNumber {
                    attributeItem?.value = value.floatValue
                }
                else {
                    attributeItem?.value = defaultValue.floatValue
                }

                filterAttributes.append(filterAttribute)
            }
        }
        else {
            filterAttributes = rawAttributes()
        }

        DispatchQueue.main.async {
            self.reloadFilter()
        }
    }
    
    private func reloadFilter() {
        if let _ = self.rawFilter {
            self.enabledEditing = true
            self.filter = CIRawFilter(rawURL: self.rawFilter?.rawURL, params: Dictionary(uniqueKeysWithValues: self.filterAttributes.map({ ($0.key, $0.value) })))
        }
        else {
            self.enabledEditing = false
            self.filter = nil
        }
        (self.view as? UITableView)?.reloadData()
    }

    private func rawAttributes() -> [CIFilterAttributes] {
        // https://developer.apple.com/documentation/coreimage/cifilter/raw_image_options
        return [
            CIFilterAttributes(key: CIRAWFilterOption.neutralTemperature.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Temperature".localized, attributeKey: CIRAWFilterOption.neutralTemperature.rawValue, defaultValue: 2000, minimumValue: 2000, maximumValue: 20000)]),
            CIFilterAttributes(key: CIRAWFilterOption.neutralTint.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Tint".localized, attributeKey: CIRAWFilterOption.neutralTint.rawValue, defaultValue: 0, minimumValue: -150, maximumValue: 150)]),
            CIFilterAttributes(key: CIRAWFilterOption.baselineExposure.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Baseline Exposure".localized, attributeKey: CIRAWFilterOption.baselineExposure.rawValue, defaultValue: 0, minimumValue: -3, maximumValue: 3)]), // no min max
            CIFilterAttributes(key: kCIInputEVKey, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "EV", attributeKey: kCIInputEVKey, defaultValue: 0, minimumValue: -3, maximumValue: 3)]),
            CIFilterAttributes(key: kCIInputBiasKey, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Bias".localized, attributeKey: kCIInputBiasKey, defaultValue: 0, minimumValue: -3, maximumValue: 25)]),
            CIFilterAttributes(key: CIRAWFilterOption.enableSharpening.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Sharpening".localized, attributeKey: CIRAWFilterOption.enableSharpening.rawValue, boolValue: true)]),
//            CIFilterAttributes(key: CIRAWFilterOption.neutralLocation.rawValue, attributeType: kCIAttributeTypePosition, attributes: [CIFilterAttributeItem(name: "NeutralLocationX", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 0), CIFilterAttributeItem(name: "NeutralLocationY", defaultValue: 0, minimumValue: 0, maximumValue: 1, offset: 1)]), // no min max
            CIFilterAttributes(key: CIRAWFilterOption.enableVendorLensCorrection.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Vendor Lens Correction".localized, attributeKey: CIRAWFilterOption.enableVendorLensCorrection.rawValue, boolValue: true)]),
            CIFilterAttributes(key: CIRAWFilterOption.disableGamutMap.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Disable Gamut Map".localized, attributeKey: CIRAWFilterOption.disableGamutMap.rawValue, boolValue: false)]),
            CIFilterAttributes(key: CIRAWFilterOption.boostAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Boost".localized, attributeKey: CIRAWFilterOption.boostAmount.rawValue, defaultValue: 1, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.boostShadowAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Boost Shadow".localized, attributeKey: CIRAWFilterOption.boostShadowAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 2)]),
            CIFilterAttributes(key: CIRAWFilterOption.enableChromaticNoiseTracking.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Noise Tracking".localized, attributeKey: CIRAWFilterOption.enableChromaticNoiseTracking.rawValue, boolValue: true)]),
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction".localized, attributeKey: CIRAWFilterOption.noiseReductionAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)]), // no default
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionDetailAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction Detail".localized, attributeKey: CIRAWFilterOption.noiseReductionDetailAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.colorNoiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Color Noise Reduction".localized, attributeKey: CIRAWFilterOption.colorNoiseReductionAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionContrastAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction Contrast".localized, attributeKey: CIRAWFilterOption.noiseReductionContrastAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.noiseReductionSharpnessAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Noise Reduction Sharpness".localized, attributeKey: CIRAWFilterOption.noiseReductionSharpnessAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: CIRAWFilterOption.luminanceNoiseReductionAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Luminance Noise Reduction".localized, attributeKey: CIRAWFilterOption.luminanceNoiseReductionAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
//            CIFilterAttributes(key: CIRAWFilterOption.neutralChromaticityX.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Chromaticity X".localized, defaultValue: 0.5, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
//            CIFilterAttributes(key: CIRAWFilterOption.neutralChromaticityY.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Chromaticity Y".localized, defaultValue: 0.5, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
            CIFilterAttributes(key: CIRAWFilterOption.moireAmount.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Moire".localized, attributeKey: CIRAWFilterOption.moireAmount.rawValue, defaultValue: 0, minimumValue: 0, maximumValue: 1)]),
            CIFilterAttributes(key: "inputHueMagMR", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Magenta / Red".localized, attributeKey: "inputHueMagMR", defaultValue: 0, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
            CIFilterAttributes(key: "inputHueMagBM", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Blue / Magenta".localized, attributeKey: "inputHueMagBM", defaultValue: 0, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
            CIFilterAttributes(key: "inputHueMagYG", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Yellow / Green".localized, attributeKey: "inputHueMagYG", defaultValue: 0, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
            CIFilterAttributes(key: "inputHueMagCB", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Cyan / Blue".localized, attributeKey: "inputHueMagCB", defaultValue: 0, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
            CIFilterAttributes(key: "inputHueMagRY", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Red / Yellow".localized, attributeKey: "inputHueMagRY", defaultValue: 0, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
            CIFilterAttributes(key: "inputHueMagGC", attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Green / Cyan".localized, attributeKey: "inputHueMagGC", defaultValue: 0, minimumValue: 0, maximumValue: 1, isIntensity: false)]), // no min max
//            CIFilterAttributes(key: CIRAWFilterOption.allowDraftMode.rawValue, attributeType: kCIAttributeTypeBoolean, attributes: [CIFilterAttributeItem(name: "Draft Mode", boolValue: false)]),
//            CIFilterAttributes(key: CIRAWFilterOption.scaleFactor.rawValue, attributeType: kCIAttributeTypeScalar, attributes: [CIFilterAttributeItem(name: "Scale Factor", defaultValue: 1, minimumValue: 0, maximumValue: 1)]),
        ]
    }

    private func installFilters(with filters: [CIFilter]? = nil) {
        filterAttributes = rawAttributes()
    }

    @objc dynamic var filter: CIFilter?

    private var enabledEditing: Bool = false {
        didSet {
            view.alpha = enabledEditing ? 1 : 0.5
        }
    }

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

                self.filter = CIRawFilter(rawURL: self.rawFilter?.rawURL, params: Dictionary(uniqueKeysWithValues: self.filterAttributes.map({ ($0.key, $0.value) })))
            }

            cell.isUserInteractionEnabled = enabledEditing

            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: RawEditorApp.info.identifier + "CIAdjustmentSliderCell") as! CIAdjustmentSliderCell

            if let displayImage = sliderCellDisplayImage(for: filterAttribute, in: CGSize(width: 20, height: 20)) {
                cell.iconView.image = displayImage
            }
            else {
                cell.titleLabel.text = attributeItem.name
            }

            cell.highlightedColor = RawEditorApp.info.themeColor

            cell.slider.minimumValue = attributeItem.minimumValue
            cell.slider.maximumValue = attributeItem.maximumValue
            cell.slider.defaultValue = attributeItem.defaultValue
            cell.slider.value = attributeItem.value

            cell.resetButton.isHidden = !attributeItem.hasChanges
            cell.resetButtonDidTapHandler = {
                attributeItem.value = attributeItem.defaultValue
                cell.resetButton.isHidden = !attributeItem.hasChanges

                cell.slider.value = attributeItem.value

                self.filter = CIRawFilter(rawURL: self.rawFilter?.rawURL, params: Dictionary(uniqueKeysWithValues: self.filterAttributes.map({ ($0.key, $0.value) })))
            }

            cell.sliderDidChangeHandler = { value in
                attributeItem.value = value

                cell.resetButton.isHidden = !attributeItem.hasChanges

                self.filter = CIRawFilter(rawURL: self.rawFilter?.rawURL, params: Dictionary(uniqueKeysWithValues: self.filterAttributes.map({ ($0.key, $0.value) })))
            }

            cell.isUserInteractionEnabled = enabledEditing

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

extension RawEditorDockContent {
    func sliderCellDisplayImage(for filterAttributes: CIFilterAttributes, in size: CGSize) -> UIImage? {
        switch filterAttributes.key {
        case "inputHueMagMR": return twoColorDotImage(size: size, color1: .red, color2: .magenta)
        case "inputHueMagBM": return twoColorDotImage(size: size, color1: .magenta, color2: .blue)
        case "inputHueMagYG": return twoColorDotImage(size: size, color1: .green, color2: .yellow)
        case "inputHueMagCB": return twoColorDotImage(size: size, color1: .blue, color2: .cyan)
        case "inputHueMagRY": return twoColorDotImage(size: size, color1: .yellow, color2: .red)
        case "inputHueMagGC": return twoColorDotImage(size: size, color1: .cyan, color2: .green)
        default: return nil
        }
    }

    private func twoColorDotImage(size: CGSize, color1: UIColor, color2: UIColor) -> UIImage? {
        let colorImage1 = UIImage(color: color1, size: CGSize(width: size.width / 2, height: size.height))
        let colorImage2 = UIImage(color: color2, size: CGSize(width: size.width / 2, height: size.height))
        return UIGraphicsImageRenderer(size: size).imageWithCurrentContext(actions: { (ctx) in
            colorImage1?.draw(at: .zero)
            colorImage2?.draw(at: CGPoint(x: size.width / 2, y: 0))
        })?.rounded()
    }
}
