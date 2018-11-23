//
//  Resizer.BApp.swift
//  batch
//
//  Created by HYOJIN MO on 09/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

import UIKit
import Photos
import PropertyKit
import MetalPerformanceShaders

protocol ResizerAppDefaults: AppDefaults {
    var resizeFilterName: String? { get set }
    var backgroundColor: UIColor { get set }
}

extension Defaults: ResizerAppDefaults {
    var resizeFilterName: String? {
        get { return get(or: nil) }
        set { set(newValue); papLog.app.defaults.log(value:newValue ?? "Original") }
    }
    
    var backgroundColor: UIColor {
        get {
            return UIColor(rgba: get(or: 0xFFFFFFFF))
        }
        
        set { set(newValue.rgba()); papLog.app.defaults.log(value:newValue.hexCode()) }
    }
}

public class ResizerAppConfigValue: NSObject, PropertyWatchable, AppConfigAdoptableValuable {
    @objc dynamic
    public var filter: ImageEditStateValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? ResizerAppConfigValue, let filter = other.filter {
            self.filter = filter
        }
    }
}

class ResizerApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
    PHAssetFinalizableApp, EditableApp, ChargeableApp, PreviewProcessableApp, AppDockApp,
    PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp,
PhotoEditorViewControllerDelegatableApp {
    public static let taskType: AppTaskable.Type = _ResizerAppTask.self
    public static let paramType: AppTaskParamable.Type = _ResizerAppAsset.self
    
    public static var defaultConfigValue: AppConfigValuable {
        let config = ResizerAppConfigValue()
        return config
    }
    
    @objc dynamic
    public private(set) lazy var config: ResizerAppConfigValue? = type(of:self).defaultConfigValue as? ResizerAppConfigValue
    
    public private(set) lazy var content: AppDockContent? = ResizerAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = ResizerAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        var defaults = type(of: self).defaults as! ResizerAppDefaults
        
        let filter = editStateValue?.ciFilter as? CIResizeFilter
        defaults.resizeFilterName = filter?.name
        defaults.backgroundColor = filter?.backgroundColor ?? UIColor(rgb: 0xFFFFFF)
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.resizer"
        , version: "1.0"
        , phase: .develop
        , appType: ResizerApp.self
        , displayName: "Resizer".localized.localizedCapitalized
        , description: "Resize your photos by the various sizes.".localized
        , keywords: ["Resize", "Instasize", "Instafit", "No Crop"]
        , iconBundleName: R.image.resizerBAppIcon.name
        , themeColor: UIColor(rgb: 0xFA7E1E)
        , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        if let controllerContent = self.content as? ResizerAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! ResizerAppDefaults
                    let filterItem = controllerContent.getFilterItem(by: defaults.resizeFilterName)
                    (filterItem?.ciFilter as? CIResizeFilter)?.backgroundColor = defaults.backgroundColor
                    self.config?.filter = filterItem
                    self.defaultEditStateValue = filterItem
                }
            }
        }
        
        if let controllerContent = self.photoEditorDockContent as? ResizerAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! ResizerAppDefaults
                    let filterItem = controllerContent.getFilterItem(by: defaults.resizeFilterName)
                    (filterItem?.ciFilter as? CIResizeFilter)?.backgroundColor = defaults.backgroundColor
                    
                    self.config?.filter = filterItem
                }
            }
        }
    }
    
    public var doneButtonTitle: String? {
        return "Resize".localized
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
    
    static var localCharges: [Charge] {
        return self.defaultFreeBAppLocalCharges
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original, filtered)
    }
    
    public func photoEditorWillBeginProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = false
    }
    
    public func photoEditorWillEndProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = true
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        (content as? ResizerAppDockContent)?.selectItem(with: editStateValue)
    }
}

enum AspectRatioOption: Int, Codable {
    case original
    case square
    case ratio4x5
    case ratio1_91x1
    case ratio9x16
    case ratio16x9
    case ratio9x21
    case ratio21x9
    case devicePortrait
    case deviceLandscape
    
    var name: String {
        switch self {
        case .original: return "Original"
        case .square: return "1:1"
        case .ratio4x5: return "4:5"
        case .ratio1_91x1: return "1.91:1"
        case .ratio9x16: return "9:16"
        case .ratio16x9: return "16:9"
        case .ratio9x21: return "9:21"
        case .ratio21x9: return "21:9"
        case .devicePortrait: return "devicePortrait"
        case .deviceLandscape: return "deviceLandscape"
        }
    }
    
    var description: String? {
        switch self {
        case .original: return nil
        case .square: return "Square".localized
        case .ratio4x5: return "Instagram Vertical".localized
        case .ratio1_91x1: return "Instagram Landscape".localized
        case .ratio16x9: return "Youtube Landscape".localized
        case .ratio9x16: return "Instagram Story".localized
        case .ratio21x9: return "Ultra Wide".localized
        case .ratio9x21: return "Ultra Wide Vertical".localized
        case .devicePortrait: return UIDevice.current.localizedModel + " Portrait".localized
        case .deviceLandscape: return UIDevice.current.localizedModel + " Landscape".localized
        }
    }
    
    var title: String {
        return description ?? name
    }
    
    var aspectRatio: CGSize {
        switch self {
        case .original: return CGSize.zero
        case .square: return CGSize(width: 1, height: 1)
        case .ratio4x5: return CGSize(width: 4, height: 5)
        case .ratio1_91x1: return CGSize(width: 1.91, height: 1)
        case .ratio16x9: return CGSize(width: 16, height: 9)
        case .ratio9x16: return CGSize(width: 9, height: 16)
        case .ratio9x21: return CGSize(width: 9, height: 21)
        case .ratio21x9: return CGSize(width: 21, height: 9)
        case .devicePortrait: return UIScreen.main.nativeBounds.size
        case .deviceLandscape: return CGSize(width: UIScreen.main.nativeBounds.size.height, height: UIScreen.main.nativeBounds.width)
        }
    }
    
    func aspectFitSize(in size: CGSize) -> CGSize {
        return aspectFit(in: size).size
    }
    
    func aspectFit(in size: CGSize) -> CGRect {
        guard self != .original else { return CGRect(origin: .zero, size: size) }
        return AVMakeRect(aspectRatio: aspectRatio, insideRect: CGRect(origin: .zero, size: size))
    }
    
    var normalizedSize: CGSize {
        return aspectRatio.aspectFit(in: CGSize(width: 1, height: 1))
    }
}

class CIResizeFilter: CIFilter {
    var aspectRatioOption: AspectRatioOption = .original
    var backgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)
    
    init(aspectRatioOption: AspectRatioOption) {
        super.init()
        self.name = aspectRatioOption.name
        self.aspectRatioOption = aspectRatioOption
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc dynamic var inputImage : CIImage?
    
    override var outputImage: CIImage? {
        return autoreleasepool {
            guard let image = value(forKey: kCIInputImageKey) as? CIImage, let cgImage = CIContext().createCGImage(image, from: image.extent) else {
                return nil
            }
            
            let inputSize = image.extent.size
            let outputSize = aspectRatioOption.aspectFitSize(in: inputSize)
            let outputRect = CGRect(origin: .zero, size: outputSize)
            let aspectFitRect = AVMakeRect(aspectRatio: inputSize, insideRect: outputRect)
            
            let width = outputSize.width
            let height = outputSize.height
            let bitsPerComponent = cgImage.bitsPerComponent
            let bytesPerRow = cgImage.bytesPerRow
            let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = cgImage.bitmapInfo
            
            let ctx = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
            
            ctx?.interpolationQuality = .high
            ctx?.setFillColor(backgroundColor.cgColor)
            ctx?.fill(outputRect)
            ctx?.draw(cgImage, in: aspectFitRect)
            
            if let result = ctx?.makeImage() {
                return CIImage(cgImage: result)
            }
            else {
                return nil
            }
        }
    }
}

class CIResizeFilterItem: CIFilterItem {
    override init(_ filter: CIFilter? = nil) {
        super.init(filter)
    }
    
    convenience init(_ filter: CIFilter? = nil, backgroundColor: UIColor?) {
        self.init(filter)
        
        self.backgroundColor = backgroundColor ?? UIColor(rgb: 0xFFFFFF)
    }
    
    private var backgroundColor: UIColor {
        set {
            (ciFilter as? CIResizeFilter)?.backgroundColor = newValue
        }
        
        get {
            return (ciFilter as? CIResizeFilter)?.backgroundColor ?? UIColor(rgb: 0xFFFFFF)
        }
    }
    
    override var normalizedSize: CGSize? {
        return (ciFilter as? CIResizeFilter)?.aspectRatioOption.normalizedSize
    }
    
    override var color: UIColor? {
        return self.backgroundColor
    }
    
    override func playerItem(with video: AVAsset, for exporting: Bool = false) -> AVPlayerItem? {
        guard
            let videoTrack = video.tracks(withMediaType: .video).first,
            let normalizedSize = self.normalizedSize
        else { return nil }
        
        let composition = AVMutableComposition()
        guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return nil }
        if (try? videoCompositionTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: video.duration), of: videoTrack, at: CMTime.zero)) == nil {
            composition.removeTrack(videoCompositionTrack)
        }
        
        videoCompositionTrack.preferredTransform = videoTrack.preferredTransform
        
        if let audioTrack = video.tracks(withMediaType: .audio).first, let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            if (try? compositionTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: video.duration), of: audioTrack, at: CMTime.zero)) == nil {
                composition.removeTrack(compositionTrack)
            }
        }
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        var layerTransform = CGAffineTransform.identity
        
        if exporting {
            let inputSize = videoCompositionTrack.naturalSize.applying(videoCompositionTrack.preferredTransform).magnitude
            let outputSize = normalizedSize.applying(CGAffineTransform(scaleX: inputSize.maxLength, y: inputSize.maxLength))
            let videoRect = AVMakeRect(aspectRatio: inputSize, insideRect: CGRect(origin: .zero, size: outputSize))
            
            let outputAspectRatio = outputSize.height / outputSize.width
            
            let scaleX = videoRect.height / inputSize.height
            let scaleY = videoRect.width / inputSize.width
            
            let isInputPortrait = inputSize.height >= inputSize.width
            let isOutputPortrait = outputSize.height >= outputSize.width
            let translationRatio = isOutputPortrait ? 1 : outputAspectRatio
            
            let translationX = videoRect.origin.x / scaleX
            let translationY = videoRect.origin.y / scaleY
            
            videoComposition.renderSize = outputSize
            
            let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let translateTransform = CGAffineTransform(translationX: translationX, y: translationY)
            
            layerTransform = CGAffineTransform.identity
                .concatenating(videoCompositionTrack.preferredTransform)
                .concatenating(translateTransform)
                .concatenating(scaleTransform)
        }
        else {
            let inputSize = videoCompositionTrack.naturalSize
            let videoSize = videoCompositionTrack.naturalSize.applying(videoCompositionTrack.preferredTransform).magnitude
            let outputSize = normalizedSize.applying(CGAffineTransform(scaleX: inputSize.maxLength, y: inputSize.maxLength).concatenating(videoCompositionTrack.preferredTransform.inverted())).magnitude
            let videoRect = AVMakeRect(aspectRatio: inputSize, insideRect: CGRect(origin: .zero, size: outputSize))
            
            let outputAspectRatio = outputSize.height / outputSize.width
            
            let isInputPortrait = (inputSize != videoSize && videoSize.height >= videoSize.width)
            let scaleRatio = isInputPortrait ? outputAspectRatio : 1
            
            let scaleX = (videoRect.width / inputSize.width) * scaleRatio
            let scaleY = (videoRect.height / inputSize.height) / scaleRatio
            
            let isOutputPortrait = normalizedSize.height >= normalizedSize.width
            let translationRatio = isOutputPortrait ? 1 : outputAspectRatio
            
            let translationX = videoRect.origin.x / (videoRect.width / inputSize.width)
            let translationY = videoRect.origin.y / (videoRect.height / inputSize.height)
            
            videoComposition.renderSize = outputSize.applying(videoCompositionTrack.preferredTransform).magnitude
            
            let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let translateTransform = CGAffineTransform(translationX: translationX, y: translationY)
            
            layerTransform = CGAffineTransform.identity
                .concatenating(translateTransform)
                .concatenating(scaleTransform)
        }
        
        func makeVideoRenderWidth(_ width: CGFloat) -> CGFloat {
            return width.remainder(dividingBy: 4) == 0 ? width : width - width.truncatingRemainder(dividingBy: 4)
        }
        
        func makeVideoRenderSize(_ size: CGSize) -> CGSize {
            return CGSize(width: makeVideoRenderWidth(size.width), height: makeVideoRenderWidth(size.height))
        }
        
        videoComposition.renderSize = makeVideoRenderSize(videoComposition.renderSize)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        layerInstruction.setTransform(layerTransform, at: CMTime.zero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.backgroundColor = backgroundColor.cgColor
        instruction.timeRange = CMTimeRange(start: CMTime.zero, duration: video.duration)
        instruction.layerInstructions = [layerInstruction]

        videoComposition.instructions = [instruction]
        
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = videoComposition
        
        return playerItem
    }
}

fileprivate class ResizerAppDockContent: NSObject, PropertyWatchable, AppDockContent {
    private lazy var filters: [CIResizeFilter] = [
        CIResizeFilter(aspectRatioOption: AspectRatioOption.square),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.ratio4x5),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.ratio1_91x1),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.ratio9x16),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.ratio16x9),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.ratio21x9),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.ratio9x21),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.devicePortrait),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.deviceLandscape),
    ]
    
    struct CIFilterCollectionItem: AppUICollectionItem {
        var title: String?
        var image: UIImage?
        var action: (() -> Void)?
        
        var filter: CIFilter?
    }
    
    @objc dynamic var filterItem: CIFilterItem?
    
    private var selectedFilter: CIResizeFilter?
    private var selectedBackgroundColor: UIColor? {
        didSet {
            let buttonSize = CGSize(width: 80, height: 20)
            let image = UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: buttonSize).inset(by: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)), cornerRadius: 6), fillColor: selectedBackgroundColor ?? UIColor(rgb: 0xFFFFFF), strokeColor: .white)?.withRenderingMode(.alwaysOriginal)
            colorPickerButton.setImage(image, for: .normal)
        }
    }
    
    private lazy var items: [CIFilterCollectionItem] = {
        var items = [CIFilterCollectionItem]()
        
        let imageInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        let imageSize = CGSize(width: 32, height: 32)
        
        items.append(CIFilterCollectionItem(title: "Original".localized, image: UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize).inset(by: imageInsets), cornerRadius: imageSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.2), strokeColor: .white), action: {
            self.selectedFilter = nil
            self.filterItem = CIResizeFilterItem(backgroundColor: self.selectedBackgroundColor)
        }, filter: nil))
        
        items += self.filters.map({ (filter) -> CIFilterCollectionItem in
            let iconSize = imageSize.applying(CGAffineTransform(scaleX: filter.aspectRatioOption.normalizedSize.width, y: filter.aspectRatioOption.normalizedSize.height))
            let icon = UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: iconSize).inset(by: imageInsets), cornerRadius: iconSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.9), strokeColor: .white)
            
            return CIFilterCollectionItem(title: filter.aspectRatioOption.title, image: icon, action: {
                self.selectedFilter = filter
                self.filterItem = CIResizeFilterItem(filter, backgroundColor: self.selectedBackgroundColor)
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
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(collectionView)
        view.addSubview(toolBar)
        
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.bottomAnchor.constraint(equalTo: toolBar.bottomAnchor, constant: 4).isActive = true
        toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        toolBar.heightAnchor.constraint(lessThanOrEqualToConstant: 32).isActive = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: toolBar.topAnchor, constant: 4).isActive = true
        
        toolBar.addArrangedSubview(colorPickerButton)
        
        return view
    }()
    
    lazy var colorPickerButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 4, right: 4)
        button.addTarget(self, action: #selector(self.openColorPicker), for: .touchUpInside)
        return button
    }()
    
    private lazy var colors: [Int] = [
        0xFFFFFF,
        0x000000,
        0x6ABB72,
        0x3ABB9D,
        0x4DA664,
        0x2CA786,
        0x5CADCF,
        0x3585C5,
        0x4590B6,
        0x2F6CAD,
        0x485675,
        0x29334D,
        0x9069B5,
        0x533D7F,
        0xF2D46F,
        0xF7C23E,
        0xF79E3D,
        0xEE7841,
        0xE66B5B,
        0xCC4846,
        0xDC5047,
        0xB33234,
        0xA28F85,
        0xEFEFEF,
        0xD1D5D8,
        0x75706B
    ]
    
    @objc private func openColorPicker() {
        let picker = UIAlertController.actionSheet(title: "\n" + "Background Color".localized, message: nil)
        picker.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        for color in colors {
            let c = UIColor(rgb: color)
            let action = UIAlertAction(title: c.hexCode(), style: .default, handler: { _ in
                self.selectedBackgroundColor = c
                self.filterItem = CIResizeFilterItem(self.selectedFilter, backgroundColor: c)
            })
            action.accessoryImage = UIImage(path: UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)).inset(by: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))), fillColor: c, strokeColor: .white)?.withRenderingMode(.alwaysOriginal)
            picker.addAction(action)
        }
        
        DispatchQueue.main.async {
            UIViewController.present(picker, animated: true)
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
        let filter = editStateValue?.ciFilter as? CIResizeFilter
        selectItem(by: filter?.name)
        
        selectedFilter = filter
        selectedBackgroundColor = filter?.backgroundColor
    }
    
    fileprivate func getFilterItem(by filterName: String?) -> CIResizeFilterItem? {
        let index = indexOfItem(by: filterName) ?? 0
        return CIResizeFilterItem(self.filters[safe: index - 1], backgroundColor: selectedBackgroundColor)
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
        collectionView.cellAppearance.selectedStateColor = ResizerApp.info.themeColor
        collectionView.cellAppearance.selectedStateBorderWidth = 2
        collectionView.cellAppearance.selectedStateCornerRadius = 6
        collectionView.reloadData()
    }
}

class _ResizerAppAsset: _FiltersAppAsset {}

private class _ResizerAppTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _ResizerAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _ResizerAppAsset)?.cancelAllRequestIDs()
        (param as? _ResizerAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _ResizerAppAsset, "TaskParamable type of this app is \(_ResizerAppAsset.self)")
        guard let _param = param as? _ResizerAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _ResizerAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: ResizerApp.self, editInfo: ["filterName": assetItem.editState.ciFilter?.name ?? ""], from: asset)
                    
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
