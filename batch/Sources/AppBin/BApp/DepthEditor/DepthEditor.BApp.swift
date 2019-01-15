//
//  DepthEditor.BApp.swift
//  batch
//
//  Created by HYOJIN MO on 09/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

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
        get { return get(or: 0) }
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
        PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
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
        defaults.depthLevel = Double(filter?.depthLevel ?? 0)
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
        return "Resize".localized
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image// fastly check hasDepthData (!= DepthEffect)
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

    public lazy var previewOriginalImageCache: NSCache<NSString, CIImage> = NSCache<NSString, CIImage>()
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = cachedOriginalImage(with: appAsset.asset, targetSize: targetSize)
        

        //TEST
        if let metadataOrientation = appAsset.asset.asURL?.asData?.getMetadataValue(property: ImageMetadata.Orientation) as? UInt32{
            (appAsset.editState.ciFilter as? CIDepthMaskFilter)?.depthData = appAsset.asset.asURL?.asDepthData
            (appAsset.editState.ciFilter as? CIDepthMaskFilter)?.depthLevel = CGFloat((self.content as? DepthEditorAppDockContent)?.depthLevelSlider.value ?? 0)
//            print("depthLevel",(appAsset.editState.ciFilter as? CIDepthMaskFilter)?.depthLevel)
            (appAsset.editState.ciFilter as? CIDepthMaskFilter)?.originalOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation)
        }
        //TEST

        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original?.asUIImage, filtered?.asUIImage)
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
}

private enum DepthEditMode: Int, Codable {
    case original
    case blur

    var name: String {
        switch self {
        case .original: return "Original"
        case .blur: return "Blur"
        }
    }

    var description: String? {
        switch self {
        case .original: return nil
        case .blur: return "Blur".localized
        }
    }

    var title: String {
        return description ?? name
    }
}

private class CIDepthMaskFilter: CIFilter {
    //
    var depthData:AVDepthData?
    var depthLevel:CGFloat = 0.5
    var originalOrientation:CGImagePropertyOrientation?
    //

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
            guard let image = inputImage
                    , let depthDataMapPixelBuffer = depthData?.depthDataMap else {
                print("No depth data found.")
                return nil
            }

            depthDataMapPixelBuffer.normalize()

            let depthImage = CIImage(cvPixelBuffer: depthDataMapPixelBuffer)
            let scale = image.extent.maxLength / depthImage.extent.maxLength
            var maskingDepthImage = createBandPassMask(for: depthImage, withFocus: depthLevel, andScale: scale)
//            var invertedMaskImage = mask.applyingFilter("CIColorInvert")

            if let o = originalOrientation{
                maskingDepthImage = maskingDepthImage.oriented(o)
            }
            
            return blur(image: image, mask: maskingDepthImage)


//            if let bImage = CIImage(cgImage: image.asCGImage?.blur()) {
//                return image.applyingFilter("CIBlendWithMask",
//                        parameters: ["inputBackgroundImage": bImage,
//                                     "inputMaskImage": invertedMaskImage])
//            }

//            return image.applyingFilter("CIMaskedVariableBlur", parameters: ["inputMask" : invertedMaskImage, "inputRadius": 15.0])
        }
    }

    func createHighPassMask(for depthImage: CIImage,
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

    func createBandPassMask(for depthImage: CIImage,
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

    func comic(image: CIImage, mask: CIImage) -> CIImage {

        let bg = image.applyingFilter("CIComicEffect")

        let filtered = image.applyingFilter("CIBlendWithMask",
                parameters: ["inputBackgroundImage": bg,
                             "inputMaskImage": mask])

        return filtered
    }

    func greenScreen(image: CIImage, background: CIImage, mask: CIImage) -> CIImage {

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

    func blur(image: CIImage, mask: CIImage) -> CIImage {

        let blurRadius: CGFloat = 10
        let crop = CIVector(x: 0,
                y: 0,
                z: image.extent.size.width,
                w: image.extent.size.height)

        let invertedMask = mask.applyingFilter("CIColorInvert")

        let blurred = image.applyingFilter("CIMaskedVariableBlur",
                parameters: ["inputMask": invertedMask,
                             "inputRadius": blurRadius])

        let filtered = blurred.applyingFilter("CICrop",
                parameters: ["inputRectangle": crop])

        return filtered
    }
}

fileprivate class DepthEditorAppDockContent: NSObject, PropertyWatchable, AppDockContent {
    private lazy var filters: [CIDepthMaskFilter] = [
        CIDepthMaskFilter(.original),
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

        let originalFilter = self.filters[0]

        items.append(CIFilterCollectionItem(title: "Original".localized, image: UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize).inset(by: imageInsets), cornerRadius: imageSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.2), strokeColor: .white), action: {
            self.selectedFilter = originalFilter
            self.filterItem = CIFilterItem(originalFilter)
        }, filter: originalFilter))

        items += self.filters[1...].map({ (filter) -> CIFilterCollectionItem in
            let icon = UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize).inset(by: imageInsets), cornerRadius: imageSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.9), strokeColor: .white)

            return CIFilterCollectionItem(title: filter.depthEditMode.title, image: icon, action: {
                self.selectedFilter = filter
                self.filterItem = CIFilterItem(filter)
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
        view.centerNotchColor = .red
        view.numberOfNotches = 20
        return view
    }()

    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(collectionView)
        view.addSubview(toolBar)
        view.translatesAutoresizingMaskIntoConstraints = false

        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 4).isActive = true
        toolBar.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30).isActive = true
        view.trailingAnchor.constraint(greaterThanOrEqualTo: toolBar.trailingAnchor, constant: 30).isActive = true
        toolBar.heightAnchor.constraint(lessThanOrEqualToConstant: 32).isActive = true
        toolBar.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        toolBar.widthAnchor.constraint(lessThanOrEqualToConstant: 320).isActive = true
        toolBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        toolBar.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 4).isActive = true

        toolBar.addArrangedSubview(depthLevelSlider)
        
        depthLevelSlider.addTarget(self, action: #selector(self.depthLevelDidChange), for: .valueChanged)
        depthLevelSlider.defaultValue = 0.5

        return view
    }()
    
    @objc func depthLevelDidChange() {
        DispatchQueue.main.async {
            self.filterItem = CIFilterItem(self.selectedFilter)
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

        selectedFilter = filter
        
        depthLevelSlider.value = Float(filter?.depthLevel ?? 0)
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
        preferences.preferredHeight = 120
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

class _DepthEditorAppAsset: _FiltersAppAsset {}

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
