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
    var borderWidth: Double { get set }
}

extension Defaults: ResizerAppDefaults {
    var resizeFilterName: String? {
        get { return get(or: "Original") }
        set { set(newValue); papLog.app.defaults.log(value:newValue ?? "Original") }
    }
    
    var backgroundColor: UIColor {
        get {
            return UIColor(rgba: get(or: 0xFFFFFFFF))
        }
        
        set { set(newValue.rgba()); papLog.app.defaults.log(value:newValue.hexCode()) }
    }
    
    var borderWidth: Double {
        get { return get(or: 0) }
        set { set(newValue); papLog.app.defaults.log(value:newValue) }
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
    PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
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
        
        let filter = editStateValue?.ciFilter as? CIFrameFillFilter
        defaults.resizeFilterName = filter?.name
        defaults.backgroundColor = filter?.backgroundColor ?? UIColor(rgb: 0xFFFFFF)
        defaults.borderWidth = Double(filter?.borderWidth ?? 0)
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.resizer"
        , version: "1.1"
        , phase: .release
        , appType: ResizerApp.self
            , displayName: "Framer".localized.localizedCapitalized
            , description: "Resize and fill to fit your photos by the various sizes.".localized
            , keywords: ["Resize", "Instasize", "Instafit", "No Crop", "Fit", "Scale", "Size","Transform","Instagram","Insta"]
        , iconBundleName: R.image.resizerBAppIcon.name
        , themeColor: UIColor(rgb: 0xFFE567)
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
                    (filterItem?.ciFilter as? CIFrameFillFilter)?.backgroundColor = defaults.backgroundColor
                    (filterItem?.ciFilter as? CIFrameFillFilter)?.borderWidth = CGFloat(defaults.borderWidth)
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
                    (filterItem?.ciFilter as? CIFrameFillFilter)?.backgroundColor = defaults.backgroundColor
                    (filterItem?.ciFilter as? CIFrameFillFilter)?.borderWidth = CGFloat(defaults.borderWidth)
                    
                    self.config?.filter = filterItem
                }
            }
        }
    }
    
    public var doneButtonTitle: String? {
        return "Re-frame".localized
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
    case ratio12x6_75
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
        case .ratio12x6_75: return "12:6.75"
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
        case .ratio12x6_75: return "Twitter".localized
        case .ratio4x5: return "Instagram Vertical".localized
        case .ratio1_91x1: return "Instagram Landscape".localized
        case .ratio16x9: return "Youtube Landscape".localized
        case .ratio9x16: return "Instagram Story"
        case .ratio21x9: return "Ultra Wide".localized
        case .ratio9x21: return "Ultra Wide Vertical".localized
        case .devicePortrait: return "\(UIDevice.current.localizedModel) \("Portrait".localized)"
        case .deviceLandscape: return "\(UIDevice.current.localizedModel) \("Landscape".localized)"
        }
    }
    
    var title: String {
        return description ?? name
    }
    
    var aspectRatio: CGSize {
        switch self {
        case .original: return CGSize.zero
        case .square: return CGSize(width: 1, height: 1)
        case .ratio12x6_75: return CGSize(width: 12, height: 6.75)
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

private class CIFrameFillFilter: CIFilter {
    enum FillMode{
        case color
        case blurredInput
    }

    var aspectRatioOption: AspectRatioOption = .original

    var backgroundColor: UIColor = UIColor(rgb: 0xFFFFFF)
    var fillMode:FillMode = .color

    var borderWidth: CGFloat = 0
    
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
            var outputSize = aspectRatioOption.aspectFitSize(in: inputSize)
            
            let borderInset = borderWidth * (outputSize.minLength / 4)
            let maximumBorderInset = borderWidth * (outputSize.maxLength / 4)
            if aspectRatioOption == .original {
                if outputSize.height > outputSize.width {
                    outputSize.height -= (maximumBorderInset - borderInset) * 2
                }
                else {
                    outputSize.width -= (maximumBorderInset - borderInset) * 2
                }
            }
            let outputRect = CGRect(origin: .zero, size: outputSize)
            let aspectFitRect = AVMakeRect(aspectRatio: inputSize, insideRect: outputRect.inset(by: UIEdgeInsets(top: borderInset, left: borderInset, bottom: borderInset, right: borderInset)))
            
            let width = outputSize.width
            let height = outputSize.height
            let bitsPerComponent = cgImage.bitsPerComponent
            let bytesPerRow = cgImage.bytesPerRow
            let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = cgImage.bitmapInfo
            
            let ctx = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

            ctx?.interpolationQuality = .high

            switch(fillMode){
                case .color:
                    ctx?.setFillColor(backgroundColor.cgColor)
                    ctx?.fill(outputRect)
                            
                case .blurredInput:

                    var bgSourceImage:CGImage? = cgImage
                    if outputRect.size.area != cgImage.size.area{
                        let o = CGPoint(x: (cgImage.size.width-outputRect.width)/2, y: (cgImage.size.height-outputRect.height)/2)
                        bgSourceImage = cgImage.cropping(to: CGRect(origin: o, size: outputRect.size))
                    }

                    if let bgImage = bgSourceImage?.blur(){
                        ctx?.draw(bgImage, in: outputRect)
                    }else{
                        ctx?.setFillColor(backgroundColor.cgColor)
                        ctx?.fill(outputRect)
                    }
            }

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

private class CIFrameFilterItem: CIFilterItem {
    override init(_ filter: CIFilter? = nil) {
        super.init(filter)
    }
    
    convenience init(_ filter: CIFilter? = nil, backgroundColor: UIColor?, borderWidth: CGFloat = 0) {
        self.init(filter)
        
        self.backgroundColor = backgroundColor ?? UIColor(rgb: 0xFFFFFF)
        (ciFilter as? CIFrameFillFilter)?.borderWidth = borderWidth
    }
    
    private var backgroundColor: UIColor {
        set {
            (ciFilter as? CIFrameFillFilter)?.backgroundColor = newValue
        }
        
        get {
            return (ciFilter as? CIFrameFillFilter)?.backgroundColor ?? UIColor(rgb: 0xFFFFFF)
        }
    }
    
    var borderWidth: CGFloat {
        return (ciFilter as? CIFrameFillFilter)?.borderWidth ?? 0
    }
    
    override var doubleValue: Double? {
        return Double(borderWidth)
    }
    
    override var normalizedSize: CGSize? {
        let filter = ciFilter as? CIFrameFillFilter
        guard filter?.aspectRatioOption != .original else { return nil }
        return filter?.aspectRatioOption.normalizedSize
    }
    
    override var color: UIColor? {
        return self.backgroundColor
    }
    
    override func playerItem(with video: AVAsset, for exporting: Bool = false) -> AVPlayerItem? {
        guard
            let videoTrack = video.tracks(withMediaType: .video).first
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
        
        let normalizedSize = self.normalizedSize ?? videoCompositionTrack.naturalSize.applying(videoCompositionTrack.preferredTransform).magnitude.aspectFit(in: CGSize(width: 1, height: 1))
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        var layerTransform = CGAffineTransform.identity
        
        if exporting {
            let inputSize = videoCompositionTrack.naturalSize.applying(videoCompositionTrack.preferredTransform).magnitude
            let borderInset = borderWidth * (videoCompositionTrack.naturalSize.minLength / 4)
            let maximumBorderInset = borderWidth * (videoCompositionTrack.naturalSize.maxLength / 4)
            var outputSize = normalizedSize.applying(CGAffineTransform(scaleX: inputSize.maxLength, y: inputSize.maxLength))
            if (ciFilter as? CIFrameFillFilter)?.aspectRatioOption == .original {
                if outputSize.height > outputSize.width {
                    outputSize.height -= (maximumBorderInset - borderInset) * 2
                }
                else {
                    outputSize.width -= (maximumBorderInset - borderInset) * 2
                }
            }
            
            let videoRect = AVMakeRect(aspectRatio: inputSize, insideRect: CGRect(origin: .zero, size: outputSize).inset(by: UIEdgeInsets(top: borderInset, left: borderInset, bottom: borderInset, right: borderInset)))
            
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
            let borderInset = borderWidth * (videoCompositionTrack.naturalSize.minLength / 4)
            let maximumBorderInset = borderWidth * (videoCompositionTrack.naturalSize.maxLength / 4)
            var outputSize = normalizedSize.applying(CGAffineTransform(scaleX: inputSize.maxLength, y: inputSize.maxLength).concatenating(videoCompositionTrack.preferredTransform.inverted())).magnitude
            if (ciFilter as? CIFrameFillFilter)?.aspectRatioOption == .original {
                if outputSize.height > outputSize.width {
                    outputSize.height -= (maximumBorderInset - borderInset) * 2
                }
                else {
                    outputSize.width -= (maximumBorderInset - borderInset) * 2
                }
            }
            
            let videoRect = AVMakeRect(aspectRatio: inputSize, insideRect: CGRect(origin: .zero, size: outputSize).inset(by: UIEdgeInsets(top: borderInset, left: borderInset, bottom: borderInset, right: borderInset)))
            
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
    private lazy var filters: [CIFrameFillFilter] = [
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.original),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.square),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.ratio12x6_75),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.ratio4x5),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.ratio1_91x1),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.ratio9x16),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.ratio16x9),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.ratio21x9),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.ratio9x21),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.devicePortrait),
        CIFrameFillFilter(aspectRatioOption: AspectRatioOption.deviceLandscape),
    ]
    
    struct CIFilterCollectionItem: AppUICollectionItem {
        var title: String?
        var image: UIImage?
        var action: (() -> Void)?
        
        var filter: CIFilter?
    }
    
    @objc dynamic var filterItem: CIFilterItem?

    private var selectedFilter: CIFrameFillFilter? {
        didSet {
            updateSelectedFilterFillMode()
        }
    }

    private func updateSelectedFilterFillMode(){
        if self.selectedBackgroundColor == blurringModeBackgroundColor{
            self.selectedFilter?.fillMode = .blurredInput
        }else{
            self.selectedFilter?.fillMode = .color
        }
    }

    private var selectedBackgroundColor: UIColor? {
        didSet {
            let buttonSize = CGSize(width: 20, height: 20)
            let buttonRect = CGRect(origin: .zero, size: buttonSize).inset(by: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))

            if selectedBackgroundColor == blurringModeBackgroundColor{
                colorPickerButton.setImage(R.image.resizerBlurColorIcon()?.resize(aspectFit: buttonRect.size.screenScaled()), for: .normal)

            } else{
                let image = UIImage(path: UIBezierPath(roundedRect: buttonRect, cornerRadius: buttonRect.height), fillColor: selectedBackgroundColor ?? UIColor(rgb: 0xFFFFFF), strokeColor: .white)?.withRenderingMode(.alwaysOriginal)
                colorPickerButton.setImage(image, for: .normal)
            }

            updateSelectedFilterFillMode()
        }
    }
    private var selectedBorderWidth: CGFloat { return CGFloat(borderWidthSlider.value) }
    
    private lazy var items: [CIFilterCollectionItem] = {
        var items = [CIFilterCollectionItem]()
        
        let imageInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        let imageSize = CGSize(width: 32, height: 32)
        
        let originalFilter = self.filters[0]
        
        items.append(CIFilterCollectionItem(title: "Original".localized, image: UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize).inset(by: imageInsets), cornerRadius: imageSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.2), strokeColor: .white), action: {
            self.selectedFilter = originalFilter
            self.filterItem = CIFrameFilterItem(originalFilter, backgroundColor: self.selectedBackgroundColor, borderWidth: self.selectedBorderWidth)
        }, filter: originalFilter))
        
        items += self.filters[1...].map({ (filter) -> CIFilterCollectionItem in
            let iconSize = imageSize.applying(CGAffineTransform(scaleX: filter.aspectRatioOption.normalizedSize.width, y: filter.aspectRatioOption.normalizedSize.height))
            let icon = UIImage(path: UIBezierPath(roundedRect: CGRect(origin: .zero, size: iconSize).inset(by: imageInsets), cornerRadius: iconSize.minLength / 8), fillColor: UIColor(white: 1, alpha: 0.9), strokeColor: .white)
            
            return CIFilterCollectionItem(title: filter.aspectRatioOption.title, image: icon, action: {
                self.selectedFilter = filter
                self.filterItem = CIFrameFilterItem(filter, backgroundColor: self.selectedBackgroundColor, borderWidth: self.selectedBorderWidth)
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
    
    lazy var view: UIView = {
        let view = UIView(frame: .zero)
        view.addSubview(collectionView)
        view.addSubview(toolBar)
        
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
        collectionView.bottomAnchor.constraint(equalTo: toolBar.topAnchor, constant: 4).isActive = true
        
        toolBar.addArrangedSubview(colorPickerButton)
        toolBar.addArrangedSubview(borderWidthSlider)
        
        return view
    }()
    
    private lazy var colorPickerButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 4, right: 4)
        button.addTarget(self, action: #selector(self.openColorPicker), for: .touchUpInside)
        return button
    }()
    
    private lazy var borderWidthSlider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(self.borderWidthDidChange), for: .valueChanged)
        return slider
    }()


    private lazy var blurringModeBackgroundColor:UIColor = UIColor(rgb:0xEFFFFF)

    private lazy var colors: [UIColor] = [
        blurringModeBackgroundColor,
        UIColor(rgb:0xFFFFFF),
        UIColor(rgb:0x000000),
        UIColor(rgb:0x6ABB72),
        UIColor(rgb:0x3ABB9D),
        UIColor(rgb:0x4DA664),
        UIColor(rgb:0x2CA786),
        UIColor(rgb:0x5CADCF),
        UIColor(rgb:0x3585C5),
        UIColor(rgb:0x4590B6),
        UIColor(rgb:0x2F6CAD),
        UIColor(rgb:0x485675),
        UIColor(rgb:0x29334D),
        UIColor(rgb:0x9069B5),
        UIColor(rgb:0x533D7F),
        UIColor(rgb:0xF2D46F),
        UIColor(rgb:0xF7C23E),
        UIColor(rgb:0xF79E3D),
        UIColor(rgb:0xEE7841),
        UIColor(rgb:0xE66B5B),
        UIColor(rgb:0xCC4846),
        UIColor(rgb:0xDC5047),
        UIColor(rgb:0xB33234),
        UIColor(rgb:0xA28F85),
        UIColor(rgb:0xEFEFEF),
        UIColor(rgb:0xD1D5D8),
        UIColor(rgb:0x75706B)
    ]
    
    @objc private func openColorPicker() {
        let picker = UIAlertController.actionSheet(title: "\n" + "Background Fill Color".localized, message: nil)
        picker.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

        for color in colors {

            let blurringMode = color == blurringModeBackgroundColor
            var accessoryImage:UIImage?
            let title:String

            let accessoryImageRect = CGRect(origin: .zero, size: CGSize(width: 10, height: 10)).inset(by: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))

            if blurringMode{
                title = "Blur Background".localized
                accessoryImage = R.image.resizerBlurColorIcon()?.resize(aspectFit: accessoryImageRect.size.screenScaled())
            }else{
                title = color.hexCode()
                accessoryImage = UIImage(path: UIBezierPath(ovalIn: accessoryImageRect), fillColor: color, strokeColor: .white)?.withRenderingMode(.alwaysOriginal)
            }

            let action = UIAlertAction(title: title, style: .default, handler: { _ in
                self.selectedBackgroundColor = color
                self.filterItem = CIFrameFilterItem(self.selectedFilter, backgroundColor: color, borderWidth: self.selectedBorderWidth)
            })

            if let accessoryImage = accessoryImage{
                action.accessoryImage = accessoryImage
            }

            picker.addAction(action)
        }
        
        DispatchQueue.main.async {
            UIViewController.present(picker, animated: true)
        }
    }
    
    @objc func borderWidthDidChange() {
        let estimatedHeight = max(4, borderWidthSlider.height * CGFloat(borderWidthSlider.value)) / 6
        
        let minTrackPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: CGSize(width: estimatedHeight, height: estimatedHeight)), byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.bottomLeft], cornerRadii: CGSize(width: estimatedHeight / 2, height: estimatedHeight / 2))
        
        let maxTrackPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: CGSize(width: estimatedHeight, height: estimatedHeight)), byRoundingCorners: [UIRectCorner.topRight, UIRectCorner.bottomRight], cornerRadii: CGSize(width: estimatedHeight / 2, height: estimatedHeight / 4))
        
        borderWidthSlider.setMinimumTrackImage(UIImage(path: minTrackPath, fillColor: selectedBackgroundColor ?? .white)?.resizableImage(withCapInsets: UIEdgeInsets(top: estimatedHeight / 2, left: estimatedHeight, bottom: estimatedHeight / 2, right: 0), resizingMode: .stretch), for: .normal)
        borderWidthSlider.setMaximumTrackImage(UIImage(path: maxTrackPath, fillColor: selectedBackgroundColor ?? .white)?.resizableImage(withCapInsets: UIEdgeInsets(top: estimatedHeight / 2, left: 0, bottom: estimatedHeight / 2, right: estimatedHeight), resizingMode: .stretch), for: .normal)
        
        Timer.scheduledTimer(identifier: #function, withTimeInterval: 0.2) { timer in
            DispatchQueue.main.asyncAfter(deadline: .now()){
                self.filterItem = CIFrameFilterItem(self.selectedFilter, backgroundColor: self.selectedBackgroundColor, borderWidth: self.selectedBorderWidth)
            }
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
        let filter = editStateValue?.ciFilter as? CIFrameFillFilter
        selectItem(by: filter?.name)
        
        selectedFilter = filter
        selectedBackgroundColor = filter?.backgroundColor
        borderWidthSlider.value = Float(filter?.borderWidth ?? 0)
        
        borderWidthDidChange()
    }
    
    fileprivate func getFilterItem(by filterName: String?) -> CIFrameFilterItem? {
        let index = indexOfItem(by: filterName) ?? 0
        return CIFrameFilterItem(self.filters[safe: index], backgroundColor: selectedBackgroundColor, borderWidth: selectedBorderWidth)
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
        
        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
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