//
//  DepthEditor.BApp.swift
//  batch
//
//  Created by HYOJIN MO on 09/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//
// f/0.2+ Depth Control slider, which ranges from f/1.4 to f/16, f/1.4 is the maximum amount of blur

import UIKit
import Photos
import PropertyKit
import MetalPerformanceShaders

protocol DepthEditorAppDefaults: AppDefaults {
    var depthModeName: String? { get set }
    var depthLevel: Double { get set }
}

extension Defaults: DepthEditorAppDefaults {
    var depthModeName: String? {
        get { return get(or: "Original") }
        set { set(newValue); papLog.app.defaults.log(value:newValue ?? "Original") }
    }
    
    var depthLevel: Double {
        get { return get(or: 1) }
        set { set(newValue); papLog.app.defaults.log(value:newValue) }
    }
}

public class DepthEditorAppConfigValue: NSObject, PropertyWatchable, AppConfigAdoptableValuable {
    @objc dynamic
    public var filter: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? DepthEditorAppConfigValue, let filter = other.filter {
            self.filter = filter
        }
    }
}

class DepthEditorApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, PhotoEditorPreviewProcessableApp, AppDockApp,
        PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp,
        PhotoEditorViewControllerDelegatableApp {
    public static let taskType: AppTaskable.Type = _DepthEditorAppTask.self
    public static let paramType: AppTaskParamable.Type = _DepthEditorAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = DepthEditorAppConfigValue()
        return config
    }

    @objc dynamic
    public private(set) lazy var config: DepthEditorAppConfigValue? = type(of:self).defaultConfigValue as? DepthEditorAppConfigValue

    public private(set) lazy var content: AppDockContent? = DepthEditorAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = DepthEditorAppDockContent()

    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue

        var defaults = type(of: self).defaults as! DepthEditorAppDefaults

        let filter = editStateValue?.ciFilter as? CIDepthMaskFilter
        defaults.depthModeName = filter?.name
        defaults.depthLevel = Double(filter?.depthLevel ?? 1)
    }

    public static let info = AppInfo(
            identifier: "com.stells.batch.deptheditor"
            , version: "1.0"
            , phase: .develop
            , appType: DepthEditorApp.self
            , displayName: "Depth Editor".localized.localizedCapitalized
            , description: "Resize and fill to fit your photos by the various sizes.".localized
            , keywords: ["Resize", "Instasize", "Instafit", "No Crop", "Fit", "Scale", "Size","Transform","Instagram","Insta"]
            , iconBundleName: nil
            , themeColor: UIColor(rgb: 0xFD8B24)
            , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
            , minOSVersion: nil
    )

    required public override init() {
        super.init()

        if let controllerContent = self.content as? DepthEditorAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! DepthEditorAppDefaults
                    let filterItem = controllerContent.getFilterItem(by: defaults.depthModeName)
                    (filterItem?.ciFilter as? CIDepthMaskFilter)?.depthLevel = CGFloat(defaults.depthLevel)
                    self.config?.filter = filterItem
                    self.defaultEditStateValue = filterItem
                }
            }
        }

        if let controllerContent = self.photoEditorDockContent as? DepthEditorAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! DepthEditorAppDefaults
                    let filterItem = controllerContent.getFilterItem(by: defaults.depthModeName)
                    (filterItem?.ciFilter as? CIDepthMaskFilter)?.depthLevel = CGFloat(defaults.depthLevel)

                    self.config?.filter = filterItem
                }
            }
        }
    }

    public var doneButtonTitle: String? {
        return "Apply".localized
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image// fastly check hasDepthData (!= DepthEffect)
    }
    
    func photoEditorShouldPreview(item: AppAsset) -> Bool {
        return item.asset.imageType == .stillImage
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
    
    private lazy var previewFilterCache: NSCache<NSString, CIDepthMaskFilter> = NSCache<NSString, CIDepthMaskFilter>()

    public lazy var previewOriginalImageCache: NSCache<NSString, CIImage> = NSCache<NSString, CIImage>()
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = cachedOriginalImage(with: appAsset.asset, targetSize: targetSize)
        
        guard let currentFilter = appAsset.editState.ciFilter as? CIDepthMaskFilter else {
            completion(original?.asUIImage, nil)
            return
        }
        
        let cacheKey = (appAsset.asset.localIdentifierWithoutSplitter + currentFilter.name) as NSString
        
        if let cachedFilter = previewFilterCache.object(forKey: cacheKey) {
            cachedFilter.depthLevel = currentFilter.depthLevel
            cachedFilter.intensity = currentFilter.intensity
            cachedFilter.focusRect = currentFilter.focusRect
            
            let filtered = original?.applyFilter(ciFilter: cachedFilter)
            completion(original?.asUIImage, filtered?.asUIImage)
        }
        else {
            let depthFilter = CIDepthMaskFilter(currentFilter.depthEditMode)
            depthFilter.depthLevel = currentFilter.depthLevel
            depthFilter.intensity = currentFilter.intensity
            depthFilter.focusRect = currentFilter.focusRect
            
            previewFilterCache.setObject(depthFilter, forKey: cacheKey)
            
            DispatchQueue(label: #file + "fetchAsset", qos: .utility).async {
                depthFilter.assetURL = appAsset.asset.asURL
                
                let filtered = original?.applyFilter(ciFilter: depthFilter)
                completion(original?.asUIImage, filtered?.asUIImage)
            }
        }
    }
    
    var previewOriginalBadgeTitle: String {
        return "Depth Map"
    }
    
    func previewOriginalImageCompare(with appAsset: AppAsset, targetSize: CGSize) -> UIImage? {
        guard let currentFilter = appAsset.editState.ciFilter as? CIDepthMaskFilter else { return nil }
        let cacheKey = (appAsset.asset.localIdentifierWithoutSplitter + currentFilter.name) as NSString
        
        let cachedFilter = previewFilterCache.object(forKey: cacheKey)
        if #available(iOS 12.0, *) {
            return (cachedFilter?.portraitMatteImage ?? cachedFilter?.depthImage)?.asUIImage
        } else {
            return cachedFilter?.depthImage?.asUIImage
        }
    }

    public func photoEditorWillBeginProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = false
    }

    public func photoEditorWillEndProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = true
    }

    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        (content as? DepthEditorAppDockContent)?.selectItem(with: editStateValue)
    }
    
    func photoEditorPreviewDidTap(at normalizedPoint: CGPoint, with editStateValue: ImageEditStateValue?) {
        (content as? DepthEditorAppDockContent)?.updateItem(at: normalizedPoint, with: editStateValue)
    }
}

private enum DepthEditMode: Int, Codable {
    case original
    case aperture
    case aperture2
    case blur

    var name: String {
        switch self {
        case .original: return "Original"
        case .aperture: return "Aperture"
        case .aperture2: return "Aperture2"
        case .blur: return "Blur"
        }
    }

    var description: String? {
        switch self {
        case .original: return nil
        case .aperture: return "Aperture".localized
        case .aperture2: return "Aperture+".localized
        case .blur: return "Blur".localized
        }
    }

    var displayName: String {
        return description ?? name
    }
}

@available(iOS 12.0, *)
extension CIDepthMaskFilter {
    var portraitMatte:AVPortraitEffectsMatte? {
        return sourceImage?.portraitEffectsMatte?.applyingExifOrientation(originalOrientation ?? .up)
    }
    
    var portraitMatteImage:CIImage? {
        guard let portraitMatte = portraitMatte else { return nil }
        return CIImage(portaitEffectsMatte: portraitMatte)
    }
}

private class CIDepthMaskFilter: CIFilter {
    //
    var assetURL:URL? {
        didSet {
            let assetData = assetURL?.asData
            if let metadataOrientation = assetData?.getMetadataValue(property: ImageMetadata.Orientation) as? UInt32 {
                self.originalOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation)
            }
            
            if let assetURL = assetURL {
                if #available(iOS 12.0, *) {
                    self.sourceImage = CIImage(contentsOf: assetURL, options: [CIImageOption.auxiliaryDepth: true, CIImageOption.auxiliaryDisparity: true, CIImageOption.auxiliaryPortraitEffectsMatte: true])
                } else {
                    self.sourceImage = CIImage(contentsOf: assetURL, options: [CIImageOption.auxiliaryDepth: true, CIImageOption.auxiliaryDisparity: true])
                }
            }
        }
    }
    private(set) var depthData:AVDepthData?
    var depthImage: CIImage? {
        guard let depthData = depthData else { return nil }
        return CIImage(depthData: depthData)
    }
    private(set) var sourceImage:CIImage? {
        didSet {
            self.depthData = self.sourceImage?.depthData?.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32).applyingExifOrientation(originalOrientation ?? .up)
        }
    }
    var depthLevel:CGFloat = 1
    var intensity:CGFloat = 1
    var originalOrientation:CGImagePropertyOrientation?
    //
    
    var focusRect: CGRect?
    var isExporting: Bool = false

    var depthEditMode: DepthEditMode = .original

    init(_ depthEditMode: DepthEditMode) {
        super.init()
        self.name = depthEditMode.name
        self.depthEditMode = depthEditMode
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc dynamic var inputImage : CIImage?

    override var outputImage: CIImage? {
        return autoreleasepool {
            return depthEditMode.applyFilter(self)
        }
    }
}

fileprivate class DepthEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent {
    private lazy var filters: [CIDepthMaskFilter] = [
//        CIDepthMaskFilter(.original),
        CIDepthMaskFilter(.aperture),
        CIDepthMaskFilter(.aperture2),
        CIDepthMaskFilter(.blur)
    ]

    struct CIFilterCollectionItem: AppUICollectionItem {
        var title: String?
        var image: UIImage?
        var action: (() -> Void)?

        var filter: CIFilter?
    }

    @objc dynamic var filterItem: CIFilterItem?

    private var selectedFilter: CIDepthMaskFilter?
    
    private lazy var items: [CIFilterCollectionItem] = {
        var items = [CIFilterCollectionItem]()

        let imageInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        let imageSize = CGSize(width: 32, height: 32)

//        let originalFilter = self.filters[0]
//
//        items.append(CIFilterCollectionItem(title: "Original".localized, image: UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize).inset(by: imageInsets), cornerRadius: imageSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.2), strokeColor: .white), action: {
//            self.selectedFilter = originalFilter
//            self.filterItem = CIFilterItem(originalFilter)
//        }, filter: originalFilter))

        items += self.filters.map({ (filter) -> CIFilterCollectionItem in
            let icon = UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize).inset(by: imageInsets), cornerRadius: imageSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.9), strokeColor: .white)

            return CIFilterCollectionItem(title: filter.depthEditMode.displayName, image: icon, action: {
                filter.depthLevel = CGFloat(self.depthLevelSlider.value)
                filter.focusRect = self.selectedFilter?.focusRect
                self.filterItem = CIFilterItem(filter)
                
                self.selectedFilter = filter
            }, filter: filter)
        })

        return items
    }()

    private lazy var collectionView: AppUICollectionView = {
        let view = AppUICollectionView(items: items)
        view.cellAppearance.size = CGSize(width: 64, height: 52)
        view.cellAppearance.spacing = 1
        view.cellAppearance.imageInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        view.cellAppearance.imageContentMode = UIView.ContentMode.scaleAspectFit

        return view
    }()

    private lazy var toolBar: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.alignment = UIStackView.Alignment.fill
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 2
        return stackView
    }()

    fileprivate lazy var depthLevelSlider: PrecisionLevelSlider = {
        let view = PrecisionLevelSlider()
        view.longNotchColor = .white
        view.shortNotchColor = UIColor.init(white: 0.5, alpha: 1)
        view.centerNotchColor = .yellow
        view.numberOfNotches = 30
        return view
    }()

    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(collectionView)
        view.addSubview(toolBar)
        view.translatesAutoresizingMaskIntoConstraints = false

        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 4).isActive = true
        toolBar.heightAnchor.constraint(lessThanOrEqualToConstant: 44).isActive = true
        toolBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
//        toolBar.widthAnchor.constraint(lessThanOrEqualToConstant: 320).isActive = true
        toolBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: 52 + 20).isActive = true

        toolBar.addArrangedSubview(depthLevelSlider)
        
        depthLevelSlider.addTarget(self, action: #selector(self.depthLevelDidChange), for: .valueChanged)
        depthLevelSlider.defaultValue = 1

        return view
    }()
    
    @objc func depthLevelDidChange() {
        DispatchQueue.main.async {
            let filter = self.selectedFilter
            filter?.depthLevel = CGFloat(self.depthLevelSlider.value)
            self.filterItem = CIFilterItem(filter)
        }
    }

    var selectedEditStateValue: ImageEditStateValue?

    fileprivate func indexOfItem(by filterName: String?) -> Int? {
        return items.index(where: { $0.filter?.name == filterName })
    }

    fileprivate func selectItem(by filterName: String?) {
        let index = indexOfItem(by: filterName) ?? 0
        collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true)
    }

    fileprivate func selectItem(with editStateValue: ImageEditStateValue?) {
        let filter = editStateValue?.ciFilter as? CIDepthMaskFilter
        selectItem(by: filter?.name)
        depthLevelSlider.value = Float(filter?.depthLevel ?? 1)
        
        selectedFilter = filter
    }
    
    fileprivate func updateItem(at normalizedPoint: CGPoint, with editStateValue: ImageEditStateValue?) {
        let filter = (editStateValue?.ciFilter ?? selectedFilter) as? CIDepthMaskFilter
        filter?.focusRect = CGRect(origin: CGPoint(x: normalizedPoint.x, y: 1 - normalizedPoint.y), size: CGSize(width: 0.01, height: 0.01))
        depthLevelSlider.value = Float(filter?.depthLevel ?? 1)
        
        filterItem = CIFilterItem(filter)
        
        selectedFilter = filter
    }

    fileprivate func getFilterItem(by filterName: String?) -> CIFilterItem? {
        let index = indexOfItem(by: filterName) ?? 0
        return CIFilterItem(self.filters[safe: index])
    }

    var contentScrollable: AppDockContentScrollable? {
        return AppDockScrollableContent(collectionView.collectionView)
    }

    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 160
        return preferences
    }

    func willSetContentView(_ view: UIView, dock: AppDock) {

    }

    func didSetContentView(_ view:UIView, dock:AppDock) {
        view.tintColor = view.colorTheme.tintColor
        collectionView.tintColor = view.colorTheme.tintColor
        collectionView.cellAppearance.selectedStateColor = DepthEditorApp.info.themeColor
        collectionView.cellAppearance.selectedStateBorderWidth = 2
        collectionView.cellAppearance.selectedStateCornerRadius = 6
        collectionView.reloadData()
    }
}

class _DepthEditorAppAsset: AppAsset {
    fileprivate weak var editingContext: PHLivePhotoEditingContext?
    
    func cancelProcessing() {
        editingContext?.cancel()
        editingContext = nil
    }
}

extension _DepthEditorAppAsset: PHAssetImageEditable {
    private func filteredImage(with asset: PHAsset) -> CIImage? {
        return autoreleasepool { () -> CIImage? in
            guard let filter = self.editState.ciFilter as? CIDepthMaskFilter else { return nil }
            
            let depthFilter = CIDepthMaskFilter(filter.depthEditMode)
            depthFilter.depthLevel = filter.depthLevel
            depthFilter.intensity = filter.intensity
            depthFilter.focusRect = filter.focusRect
            depthFilter.isExporting = true
            
            depthFilter.assetURL = asset.asURL
            
            guard let ciImage = asset.asCIImage?.applyFilter(ciFilter: depthFilter) else { return nil }
            
            return ciImage
        }
    }
    
    func edit<T: ImageProcessable>(processor: T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let asset = self.asset
        
        guard let ciImage = filteredImage(with: asset) else {
            completionHandler(nil, nil, nil)
            return nil
        }
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil, nil, nil)
                return
            }
            
            DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
                autoreleasepool {
                    guard ciImage.writeJPEGRepresentationOriginally(to: item.output.renderedContentURL) else {
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

extension _DepthEditorAppAsset: PHAssetLivePhotoEditable {
    func edit<T:LivePhotoProcessable>(processor:T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let asset = self.asset
        
        guard let ciImage = filteredImage(with: asset) else {
            completionHandler(nil, nil, nil)
            return nil
        }
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil, nil, nil)
                return
            }
            
            DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
                autoreleasepool {
                    guard ciImage.writeJPEGRepresentationOriginally(to: item.output.renderedContentURL) else {
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

private class _DepthEditorAppTask: AppTaskPrototype, AppTaskable {
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
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: DepthEditorApp.self, editInfo: ["filterName": assetItem.editState.ciFilter?.name ?? ""], from: asset)

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

extension DepthEditMode {
    func applyFilter(_ filter: CIDepthMaskFilter) -> CIImage? {
        switch self {
        case .original: return nil
        case .aperture2: return DepthEditMode.Processor.applyDepthBlurEffectWithNormalizedMap(filter)
        case .blur: return DepthEditMode.Processor.applyBlurEffect(filter)
        case .aperture: return DepthEditMode.Processor.applyDepthBlurEffect(filter)
        }
    }
    
    private struct Processor {
        static func applyDepthBlurEffectWithNormalizedMap(_ filter: CIDepthMaskFilter) -> CIImage? {
            return autoreleasepool { () -> CIImage? in
                guard
                    let foreground = filter.inputImage,
                    let depthDataMapPixelBuffer = filter.depthData?.depthDataMap
                else { return nil }
                
                depthDataMapPixelBuffer.normalize()
                
                let background = CIImage(cvPixelBuffer: depthDataMapPixelBuffer)
                
                let aperture = min(22, max(1, (1 - filter.depthLevel) * 22))
                let scale = filter.isExporting ? foreground.extent.maxLength / background.extent.maxLength : 0.1
                
                var effect: CIFilter?
                
                if #available(iOS 12.0, *) {
                    effect = CIContext.shared.depthBlurEffectFilter(for: foreground, disparityImage: background, portraitEffectsMatte: filter.portraitMatteImage, orientation: filter.originalOrientation ?? .up, options: nil)
                } else {
                    effect = CIFilter(name: "CIDepthBlurEffect")
                    
                    effect?.setValue(foreground, forKey: kCIInputImageKey)
                    effect?.setValue(background, forKey: kCIInputDisparityImageKey)
                }
                
                effect?.setValue(filter.depthData?.cameraCalibrationData, forKey: "inputCalibrationData")
                effect?.setValue(aperture, forKey: "inputAperture")
                effect?.setValue(scale, forKey: "inputScaleFactor")
                
                if let focusRect = filter.focusRect {
                    effect?.setValue(CIVector(cgRect: focusRect), forKey: "inputFocusRect")
                }
                
                return effect?.outputImage
            }
        }
        
        static func applyDepthBlurEffect(_ filter: CIDepthMaskFilter) -> CIImage? {
            return autoreleasepool { () -> CIImage? in
                guard
                    let foreground = filter.inputImage,
                    let background = filter.depthImage
                    else { return nil }
                
                let aperture = min(22, max(1, (1 - filter.depthLevel) * 22))
                let scale = filter.isExporting ? foreground.extent.maxLength / background.extent.maxLength : 0.1
                
                var effect: CIFilter?
                
                if #available(iOS 12.0, *) {
                    effect = CIContext.shared.depthBlurEffectFilter(for: foreground, disparityImage: background, portraitEffectsMatte: filter.portraitMatteImage, orientation: filter.originalOrientation ?? .up, options: nil)
                } else {
                    effect = CIFilter(name: "CIDepthBlurEffect")
                    
                    effect?.setValue(foreground, forKey: kCIInputImageKey)
                    effect?.setValue(background, forKey: kCIInputDisparityImageKey)
                }
                
                effect?.setValue(filter.depthData?.cameraCalibrationData, forKey: "inputCalibrationData")
                effect?.setValue(aperture, forKey: "inputAperture")
                effect?.setValue(scale, forKey: "inputScaleFactor")
                
                if let focusRect = filter.focusRect {
                    effect?.setValue(CIVector(cgRect: focusRect), forKey: "inputFocusRect")
                }
                
                return effect?.outputImage
            }
        }
        
        static func applyBlurEffect(_ filter: CIDepthMaskFilter) -> CIImage? {
            guard let image = filter.inputImage, let depthDataMapPixelBuffer = filter.depthData?.depthDataMap else {
                return nil
            }
            
            depthDataMapPixelBuffer.normalize()
            
            let depthImage = CIImage(cvPixelBuffer: depthDataMapPixelBuffer)
            
            let scale = image.extent.maxLength / depthImage.extent.maxLength
            let maskingDepthImage = createBandPassMask(for: depthImage, withFocus: filter.depthLevel, andScale: scale)
            
            return blur(image: image, mask: maskingDepthImage)
            
            
            //            if let bImage = CIImage(cgImage: image.asCGImage?.blur()) {
            //                return image.applyingFilter("CIBlendWithMask",
            //                        parameters: ["inputBackgroundImage": bImage,
            //                                     "inputMaskImage": invertedMaskImage])
            //            }
            
            //            return image.applyingFilter("CIMaskedVariableBlur", parameters: ["inputMask" : invertedMaskImage, "inputRadius": 15.0])
        }
        
        static func createHighPassMask(for depthImage: CIImage,
                                               withFocus focus: CGFloat,
                                               andScale scale: CGFloat,
                                               isSharp: Bool = false) -> CIImage {
            
            let s = isSharp ? MaskParams.sharpSlope : MaskParams.slope
            let filterWidth =  2 / s + MaskParams.width
            let b = -s * (focus - filterWidth / 2)
            
            let mask = depthImage
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: s, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: s, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: s, w: 0),
                    "inputBiasVector": CIVector(x: b, y: b, z: b, w: 0)])
                .applyingFilter("CIColorClamp")
                .applyingFilter("CIBicubicScaleTransform",
                                parameters: ["inputScale": scale])
            
            return mask
        }
        
        static func createBandPassMask(for depthImage: CIImage,
                                               withFocus focus: CGFloat,
                                               andScale scale: CGFloat) -> CIImage {
            
            let s1 = MaskParams.slope
            let s2 = -MaskParams.slope
            let filterWidth =  2 / MaskParams.slope + MaskParams.width
            let b1 = -s1 * (focus - filterWidth / 2)
            let b2 = -s2 * (focus + filterWidth / 2)
            
            let mask0 = depthImage
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: s1, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: s1, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: s1, w: 0),
                    "inputBiasVector": CIVector(x: b1, y: b1, z: b1, w: 0)])
                .applyingFilter("CIColorClamp")
            
            let mask1 = depthImage
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: s2, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: s2, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: s2, w: 0),
                    "inputBiasVector": CIVector(x: b2, y: b2, z: b2, w: 0)])
                .applyingFilter("CIColorClamp")
            
            let combinedMask = mask0.applyingFilter("CIDarkenBlendMode",
                                                    parameters: ["inputBackgroundImage": mask1])
            
            let mask = combinedMask.applyingFilter("CIBicubicScaleTransform",
                                                   parameters: ["inputScale": scale])
            
            return mask
        }
        
        static func comic(image: CIImage, mask: CIImage) -> CIImage {
            
            let bg = image.applyingFilter("CIComicEffect")
            
            let filtered = image.applyingFilter("CIBlendWithMask",
                                                parameters: ["inputBackgroundImage": bg,
                                                             "inputMaskImage": mask])
            
            return filtered
        }
        
        static func greenScreen(image: CIImage, background: CIImage, mask: CIImage) -> CIImage {
            
            let crop = CIVector(x: 0,
                                y: 0,
                                z: image.extent.size.width,
                                w: image.extent.size.height)
            
            let croppedBG = background.applyingFilter("CICrop",
                                                      parameters: ["inputRectangle": crop])
            
            let filtered = image.applyingFilter("CIBlendWithMask",
                                                parameters: ["inputBackgroundImage": croppedBG,
                                                             "inputMaskImage": mask])
            
            return filtered
        }
        
        static func blur(image: CIImage, mask: CIImage) -> CIImage {
            
            let blurRadius: CGFloat = 10
            let crop = CIVector(x: 0,
                                y: 0,
                                z: image.extent.size.width,
                                w: image.extent.size.height)
            
            let invertedMask = mask.applyingFilter("CIColorInvert")
            
            let blurred = image.clampedToExtent().applyingFilter("CIMaskedVariableBlur",
                                               parameters: ["inputMask": invertedMask,
                                                            "inputRadius": blurRadius])
            
            let filtered = blurred.applyingFilter("CICrop",
                                                  parameters: ["inputRectangle": crop])
            
            return filtered
        }
    }
}

import Accelerate

internal class CIBokehImage {
    var cgImage: CGImage
    
    required init(cgImage: CGImage) {
        self.cgImage = cgImage
    }
    
    lazy var format: vImage_CGImageFormat = {
        guard
            let sourceColorSpace = cgImage.colorSpace else {
                fatalError("Unable to get color space")
        }
        
        return vImage_CGImageFormat(
            bitsPerComponent: UInt32(cgImage.bitsPerComponent),
            bitsPerPixel: UInt32(cgImage.bitsPerPixel),
            colorSpace: Unmanaged.passRetained(sourceColorSpace),
            bitmapInfo: cgImage.bitmapInfo,
            version: 0,
            decode: nil,
            renderingIntent: cgImage.renderingIntent)
    }()
    
    lazy var sourceBuffer: vImage_Buffer = {
        var sourceImageBuffer = vImage_Buffer()
        
        vImageBuffer_InitWithCGImage(&sourceImageBuffer,
                                     &format,
                                     nil,
                                     cgImage,
                                     vImage_Flags(kvImageNoFlags))
        
        var scaledBuffer = vImage_Buffer()
        
        vImageBuffer_Init(&scaledBuffer,
                          sourceImageBuffer.height / 3,
                          sourceImageBuffer.width / 3,
                          format.bitsPerPixel,
                          vImage_Flags(kvImageNoFlags))
        
        vImageScale_ARGB8888(&sourceImageBuffer,
                             &scaledBuffer,
                             nil,
                             vImage_Flags(kvImageNoFlags))
        
        return scaledBuffer
    }()
    
    lazy var destinationBuffer: vImage_Buffer = {
        var destinationBuffer = vImage_Buffer()
        
        vImageBuffer_Init(&destinationBuffer,
                          sourceBuffer.height,
                          sourceBuffer.width,
                          format.bitsPerPixel,
                          vImage_Flags(kvImageNoFlags))
        
        return destinationBuffer
    }()
    
    var numSides = 6
    let radius = 20
    
    func getMaximizedImage() -> UIImage? {
        let diameter = vImagePixelCount(radius * 2) + 1
        
        vImageMax_ARGB8888(&sourceBuffer,
                           &destinationBuffer,
                           nil,
                           0, 0,
                           diameter,
                           diameter,
                           vImage_Flags(kvImageNoFlags))
        
        let result = vImageCreateCGImageFromBuffer(
            &destinationBuffer,
            &format,
            nil,
            nil,
            vImage_Flags(kvImageNoFlags),
            nil)
        
        if let result = result {
            return UIImage(cgImage: result.takeRetainedValue())
        } else {
            return nil
        }
    }
    
    func getDilatedImage() -> UIImage? {
        let kernel = CIBokehImage.makeStructuringElement(ofRadius: radius,
                                                         withSides: numSides)
                                                         
        
        let diameter = vImagePixelCount(radius * 2) + 1
        
        vImageDilate_ARGB8888(&sourceBuffer,
                              &destinationBuffer,
                              0, 0,
                              kernel,
                              diameter,
                              diameter,
                              vImage_Flags(kvImageNoFlags))
        
        let result = vImageCreateCGImageFromBuffer(
            &destinationBuffer,
            &format,
            nil,
            nil,
            vImage_Flags(kvImageNoFlags),
            nil)
        
        if let result = result {
            return UIImage(cgImage: result.takeRetainedValue())
        } else {
            return nil
        }
    }
    
    /// - Tag: makeStructuringElement
    static func makeStructuringElement(ofRadius radius: Int, withSides sides: Int) -> [UInt8] {
        let diameter = (radius * 2) + 1
        
        var values = [UInt8](repeating: 255,
                             count: diameter * diameter)
        
        let angle = (Float.pi * 2) / Float(sides)
        
        stride(from: 0, through: Float(radius), by: Float(0.25)).forEach { scaledRadius in
            var previousVertex: simd_float2?
            
            stride(from: 0, through: (Float.pi * 2), by: angle).forEach {
                
                let x = Float(radius) + sin($0) * scaledRadius
                let y = Float(radius) + cos($0) * scaledRadius
                
                if let start = previousVertex {
                    let end = simd_float2(Float(x), Float(y))
                    let delta = 1.0 / max(abs(start.x - end.x), abs(start.y - end.y))
                    
                    stride(from: Float(0), through: Float(1), by: delta).forEach { t in
                        let coord = simd_mix(start, end, simd_float2(t))
                        
                        values[(Int(round(coord.x)) + Int(round(coord.y)) * diameter)] = 0
                    }
                    
                }
                
                previousVertex = simd_float2(Float(x), Float(y))
            }
        }
        
        return values
    }
}
