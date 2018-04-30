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

public class CIFilterItem: ImageEditStateValue {
    override var ciFilter: CIFilter? {
        return _filter
    }
    
    private var _filter: CIFilter?
    
    init(_ filter: CIFilter? = nil) {
        super.init()
        
        _filter = filter
    }
}

public extension StateValueSet where T: ImageEditStateValue {
    var ciFilter: CIFilter? {
        return self.iterator().reversed().first?.ciFilter
    }
}

public class PhotosFilterAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var filter: ImageEditStateValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? PhotosFilterAppConfig, let filter = other.filter{
            self.filter = filter
        }
    }
}

public class PhotosFilterApp: NSObject, BApp, KeyPathWatchable, ConfigurableApp, _ConfigurableApp, AppDockControllableApp, PHAssetFinalizableApp, PhotoPickerCollectionViewDisplayableApp, PhotoPickerViewControllerDelegatableApp {
    public static let taskType:Taskable.Type = _PhotosFilterAppTask.self
    public static let paramType:TaskParamable.Type = _PhotosFilterAppAsset.self
    
    public static var configure:(() -> PhotosFilterAppConfig)?
    
    @objc dynamic
    public private(set) lazy var config: PhotosFilterAppConfig? = PhotosFilterApp.configure?()
    public private(set) lazy var controller: AppDockContent? = createController()

    public static let info = AppInfo(
        identifier: "com.stells.batch.photosfilter"
        , version: "0.1"
        , phase: .beta
        , appType: PhotosFilterApp.self
        , displayName: "Photos Filter"
        , icon: R.image.photosFilterAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateControllerView()
        }
    }

    public var doneButtonTitle: String? {
        return "Apply".localized
    }

    public func shouldSelect(item: PHAssetItem<ImageEditStateValue>) -> Bool {
        return item.asset.imageType == .stillImage || item.asset.imageType == .burst || item.asset.mediaType == .video
    }
    
    public var finalizingPresets: [PHAssetFinalizingPresets]? {
        return [.modify]
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
        self.updateControllerView()
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
        
        static func aliasName(_ filterName: String) -> String? {
            return CIFilter.localizedName(forFilterName: filterName)
        }
    }
    
    struct CIFilters {
        static let CIPhotoEffectChrome = CIFilter(name: PhotosFilterNames.CIPhotoEffectChrome)
        static let CIPhotoEffectFade = CIFilter(name: PhotosFilterNames.CIPhotoEffectFade)
        static let CIPhotoEffectInstant = CIFilter(name: PhotosFilterNames.CIPhotoEffectInstant)
        static let CIPhotoEffectNoir = CIFilter(name: PhotosFilterNames.CIPhotoEffectNoir)
        static let CIPhotoEffectProcess = CIFilter(name: PhotosFilterNames.CIPhotoEffectProcess)
        static let CIPhotoEffectTonal = CIFilter(name: PhotosFilterNames.CIPhotoEffectTonal)
        static let CIPhotoEffectTransfer = CIFilter(name: PhotosFilterNames.CIPhotoEffectTransfer)
        static var filters: [CIFilter] {
            return [
                CIPhotoEffectChrome,
                CIPhotoEffectFade,
                CIPhotoEffectInstant,
                CIPhotoEffectProcess,
                CIPhotoEffectTransfer,
                CIPhotoEffectTonal,
                CIPhotoEffectNoir
            ].compactMap({ $0 })
        }
    }
    
    private func createController() -> AppDockContent {
        let image = PhotosFilterApp.info.icon?.asUIImage
        var items = CIFilters.filters.map({ (filter) -> BAppUICollectionView.CollectionItem in
            return BAppUICollectionView.CollectionItem(title: PhotosFilterNames.aliasName(filter.name), image: image?.applyFilter(ciFilter: filter), action: {
                self.config?.filter = CIFilterItem(filter)
            })
        })
        items.insert(BAppUICollectionView.CollectionItem(title: "Original".localized, image: image, action: { self.config?.filter = CIFilterItem() }), at: 0)
        
        let view = BAppUICollectionView(items: items)
        
        var p = AppDockContentPreferences()
        p.pinned = true
        p.minimumHeight = 100 // for test. remove this line after fixed app design
        return AppDockContentItem(view: view, preferences: p)
    }
    
    private func updateControllerView(){
        self.controller?.view.tintColor = config?.tintColor
    }
}

private class _PhotosFilterAppTask: TaskPrototype, Taskable {
    public typealias ParamType = _PhotosFilterAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        
        (param as? _PhotosFilterAppAsset)?.cancelAllRequestIDs()
        (param as? _PhotosFilterAppAsset)?.cancelProcessing()
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
        
        assetItem.runEditing({ (progress) in
            guard let progress = progress else { return }
            NotificationCenter.default.post(name: PHAssetProcessableNotification.Name.progressChanged, object: self, userInfo: [
                PHAssetProcessableNotification.UserInfo.Key.progress: progress,
                PHAssetProcessableNotification.UserInfo.Key.assetItem: assetItem
            ])
        }) { (asset, contentEditingOutput) in
            if let asset = asset, let contentEditingOutput = contentEditingOutput {
                result = PHAssetResultItem(
                    asset: asset,
                    contentEditingOutput: contentEditingOutput)
            }
            async?.end()
        }
        
        async?.waitUntilEnd()
        return result
    }
}
