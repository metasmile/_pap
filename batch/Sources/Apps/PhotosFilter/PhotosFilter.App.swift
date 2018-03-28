//
//  PhotosFilter.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 3. 28..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import DefaultsKit

public class PhotosFilterItem: AppValue {
    override var ciFilter: CIFilter? {
        return _filter
    }
    
    private var _filter: CIFilter?
    
    init(filter: CIFilter?) {
        super.init()
        
        _filter = filter
    }
}

public extension StateValueSet where T: AppValue {
    var ciFilter: CIFilter? {
        return self.iterator().reversed().first?.ciFilter
    }
}

public extension CIFilter {
    func filter(uiImage: UIImage) -> UIImage? {
        let ciImage = CIImage(image: uiImage)
        self.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = self.outputImage, let cgImage = PhotosFilterApp.sharedContext.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

public class PhotosFilterAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var filter: AppValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? PhotosFilterAppConfig, let filter = other.filter{
            self.filter = filter
        }
    }
}

class _PhotosFilterAppAsset: PHAssetItem<AppValue> {}

public class PhotosFilterApp: NSObject, KeyPathWatchable, ConfigurableApp, _ConfigurableApp, UIControllableApp, PHAssetFinalizableApp, PersistableApp {
    public static let taskType:Taskable.Type = _PhotosFilterAppTask.self
    public static let paramType:TaskParamable.Type = _PhotosFilterAppAsset.self
    
    public static var configure:(() -> PhotosFilterAppConfig)?
    
    @objc dynamic
    public private(set) lazy var config: PhotosFilterAppConfig? = PhotosFilterApp.configure?()
    public private(set) lazy var controlView: UIView? = createPreferenceView()
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.photosfilter"
        , version: "0.1"
        , phase: .beta
        , appType: PhotosFilterApp.self
        , displayName: "Photos Filter"
        , icon: R.image.revertAppIcon.name
        , policy: AppPolicy.default
    )
    
    required public override init() {
        super.init()
        
        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateConfigView()
        }
    }
    
    public func isItemEnables(for item: PHAssetItem<AppValue>) -> Bool {
        return item.asset.mediaType == .image && !item.asset.mediaSubtypes.contains(.photoLive)
    }
    
    public var finalizingOptions: PHAssetFinalizingOptions{
        return [.modify]
    }
    
    public static let sharedContext = CIContext()
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
        self.updateConfigView()
    }
}

private extension PhotosFilterApp {
    private struct PhotosFilterNames {
        static let CIPhotoEffectChrome = "CIPhotoEffectChrome"
        static let CIPhotoEffectFade = "CIPhotoEffectFade"
        static let CIPhotoEffectInstant = "CIPhotoEffectInstant"
        static let CIPhotoEffectNoir = "CIPhotoEffectNoir"
        static let CIPhotoEffectProcess = "CIPhotoEffectProcess"
        static let CIPhotoEffectTonal = "CIPhotoEffectTonal"
        static let CIPhotoEffectTransfer = "CIPhotoEffectTransfer"
    }
    
    struct PhotosFilters {
        static let CIPhotoEffectChrome = CIFilter(name: PhotosFilterNames.CIPhotoEffectChrome) ?? CIFilter()
        static let CIPhotoEffectFade = CIFilter(name: PhotosFilterNames.CIPhotoEffectFade) ?? CIFilter()
        static let CIPhotoEffectInstant = CIFilter(name: PhotosFilterNames.CIPhotoEffectInstant) ?? CIFilter()
        static let CIPhotoEffectNoir = CIFilter(name: PhotosFilterNames.CIPhotoEffectNoir) ?? CIFilter()
        static let CIPhotoEffectProcess = CIFilter(name: PhotosFilterNames.CIPhotoEffectProcess) ?? CIFilter()
        static let CIPhotoEffectTonal = CIFilter(name: PhotosFilterNames.CIPhotoEffectTonal) ?? CIFilter()
        static let CIPhotoEffectTransfer = CIFilter(name: PhotosFilterNames.CIPhotoEffectTransfer) ?? CIFilter()
        
        static var filters: [CIFilter] {
            return [
                CIPhotoEffectChrome,
                CIPhotoEffectFade,
                CIPhotoEffectInstant,
                CIPhotoEffectNoir,
                CIPhotoEffectProcess,
                CIPhotoEffectTonal,
                CIPhotoEffectTransfer
            ]
        }
    }
    
    @objc func filterDidSelect(sender: _PhotoFilterButton) {
        self.config?.filter = PhotosFilterItem(filter: sender.filter)
    }
    
    private func createPreferenceView() -> UIView {
        let view = UIStackView(frame: .zero)
        view.alignment = .fill
        view.distribution = .fillEqually
        view.axis = .horizontal
        
        for (i, filter) in PhotosFilters.filters.enumerated() {
            let button = _PhotoFilterButton(type: .system)
            button.setTitle("\(i)", for: .normal)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.2
            button.filter = filter
            button.addTarget(self, action: #selector(self.filterDidSelect), for: .touchUpInside)
            
            view.addArrangedSubview(button)
        }
        
        return view
    }
    
    private func updateConfigView(){
        if let config = self.config, let buttons = (self.controlView as? UIStackView)?.arrangedSubviews as? [UIButton]{
            for button in buttons {
                button.tintColor = config.tintColor
            }
        }
    }
}

private class _PhotoFilterButton: UIButton {
    var filter: CIFilter?
}

private class _PhotosFilterAppTask: TaskPrototype, Taskable {
    public typealias ParamType = _PhotosFilterAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        
        (param as? _PhotosFilterAppAsset)?.cancelAllRequestIDs()
    }
    
    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        assert(param is _PhotosFilterAppAsset, "TaskParamable type of this app is \(_PhotosFilterAppAsset.self)")
        guard let _param = param as? _PhotosFilterAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _PhotosFilterAppAsset, _ async: AsyncManualSignalable?) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async?.begin()
        
        assetItem.runEditing(nil) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                    asset: asset,
                    contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }
        
        async?.stopUntilEnd()
        return result
    }
}
