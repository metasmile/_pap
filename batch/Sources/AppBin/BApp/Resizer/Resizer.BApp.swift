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
}

extension Defaults: ResizerAppDefaults {
    var resizeFilterName: String? {
        get {
            return get(or: nil)
        }
        
        set { set(newValue); papLog.app.defaults.log(value:newValue ?? "Original") }
    }
}

public class ResizerAppConfigValue: NSObject, PropertyWatchable, AppConfigAdoptableValuable {
    @objc dynamic
    public var filter: ImageEditStateValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? ResizerAppConfigValue, let filter = other.filter{
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
        defaults.resizeFilterName = editStateValue?.ciFilter?.name
    }
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.resizer"
        , version: "1.0"
        , phase: .develop
        , appType: ResizerApp.self
        , displayName: "Resizer".localized.localizedCapitalized
        , description: "Resize your photos by the various sizes.".localized
        , keywords: ["Resize", "Instasize", "Instafit", "No Crop"]
        , iconBundleName: nil
        , themeColor: UIColor.red
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
    case portrait4x5
    case landscape1_91x1
    case portrait9x16
    case landscape16x9
    case portrait9x21
    case portrait21x9
    
    var name: String {
        switch self {
        case .original: return "Original"
        case .square: return "1:1"
        case .portrait4x5: return "4:5"
        case .landscape1_91x1: return "1.91:1"
        case .portrait9x16: return "9:16"
        case .landscape16x9: return "16:9"
        case .portrait9x21: return "9:21"
        case .portrait21x9: return "21:9"
        }
    }
    
    var description: String? {
        switch self {
        case .original: return nil
        case .square: return "Square"
        case .portrait4x5: return "Instagram Full"
        case .landscape1_91x1: return "Instagram Landscape"
        case .portrait9x16: return "Instagram Story"
        default: return nil
        }
    }
    
    var aspectRatio: CGSize {
        switch self {
        case .original: return CGSize.zero
        case .square: return CGSize(width: 1, height: 1)
        case .portrait4x5: return CGSize(width: 4, height: 5)
        case .landscape1_91x1: return CGSize(width: 1.91, height: 1)
        case .landscape16x9: return CGSize(width: 16, height: 9)
        case .portrait9x16: return CGSize(width: 9, height: 16)
        case .portrait9x21: return CGSize(width: 9, height: 21)
        case .portrait21x9: return CGSize(width: 21, height: 9)
        }
    }
    
    func aspectFitSize(in size: CGSize) -> CGSize {
        return aspectFit(in: size).size
    }
    
    func aspectFit(in size: CGSize) -> CGRect {
        guard self != .original else { return CGRect(origin: .zero, size: size) }
        return AVMakeRect(aspectRatio: aspectRatio, insideRect: CGRect(origin: .zero, size: size))
    }
}

class CIResizeFilter: CIFilter {
    var aspectRatioOption: AspectRatioOption = .original
    
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
            ctx?.setFillColor(UIColor.white.cgColor)
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
    
    var backgroundColor: UIColor?
    
    override var normalizedSize: CGSize? {
        return (ciFilter as? CIResizeFilter)?.aspectRatioOption.aspectRatio.aspectFit(in: CGSize(width: 1, height: 1))
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
        instruction.backgroundColor = (backgroundColor ?? UIColor(red: 1, green: 1, blue: 1, alpha: 1)).cgColor
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
        CIResizeFilter(aspectRatioOption: AspectRatioOption.portrait4x5),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.landscape1_91x1),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.portrait9x16),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.portrait9x21),
        CIResizeFilter(aspectRatioOption: AspectRatioOption.portrait21x9)
    ]
    
    @objc dynamic var filterItem: CIFilterItem?
    
    private lazy var items: [AppUICollectionView.CollectionItem] = {
        var items = [AppUICollectionView.CollectionItem]()
        
        items.append(AppUICollectionView.CollectionItem(title: "Original".localized, image: nil, action: {
            self.filterItem = CIResizeFilterItem()
        }))
        
        items += self.filters.map({ (filter) -> AppUICollectionView.CollectionItem in
            return AppUICollectionView.CollectionItem(title: (filter.aspectRatioOption.description ?? filter.name).localized, image: nil, action: {
                let filterItem = CIResizeFilterItem(filter)
                self.filterItem = filterItem
            })
        })
        
        return items
    }()
    
    lazy var view: UIView = {
        let view = AppUICollectionView(items: items)
        view.cellSize = CGSize(width: 80, height: 120)
        view.cellSpacing = 2
        view.cellImageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        
        return view
    }()
    
    var selectedEditStateValue: ImageEditStateValue?
    
    fileprivate func selectItem(by filterName: String?) {
        let index = items.index(where: { $0.title == filterName ?? "" }) ?? 0
        (view as? AppUICollectionView)?.selectItem(at: IndexPath(item: index, section: 0), animated: true)
    }
    
    fileprivate func selectItem(with editStateValue: ImageEditStateValue?) {
        selectItem(by: editStateValue?.ciFilter?.name)
    }
    
    fileprivate func getFilterItem(by filterName: String?) -> CIFilterItem? {
        let index = items.index(where: { $0.title == filterName ?? "" }) ?? 0
        return CIFilterItem(self.filters[safe: index - 1])
    }
    
    var contentScrollable: AppDockContentScrollable? {
        guard let view = view as? AppUICollectionView else { return nil }
        return AppDockScrollableContent(view.collectionView)
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
        (view as? AppUICollectionView)?.reloadData()
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
