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
        return imageEditStateValue?.ciFilter
    }
}

public class FiltersAppConfigValue: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var filter: ImageEditStateValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? FiltersAppConfigValue, let filter = other.filter{
            self.filter = filter
        }
    }
}

public class FiltersApp: NSObject, BApp, KeyPathWatchable, ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp, PreviewableApp, PreviewProcessableApp, AppDockApp,
        PhotoPickerCollectionViewDisplayableApp, PhotoPickerViewControllerDelegatableApp,
PhotoEditorViewControllerDelegatableApp {
    public static let taskType: AppTaskable.Type = _FiltersAppTask.self
    public static let paramType: AppTaskParamable.Type = _FiltersAppAsset.self
    
    public static var configure:(() -> FiltersAppConfigValue)?
    
    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = FiltersApp.configure?()
    public private(set) lazy var dockContent: AppDockContent? = FiltersAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = self.dockContent
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
    }

    public static let info = AppInfo(
        identifier: "com.stells.pap.filters"
        , version: "1.0"
        , phase: .release
        , appType: FiltersApp.self
        , displayName: "Filters".localized, description:nil, keywords:nil
        , iconBundleName: R.image.filtersBAppIcon.name
        , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
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

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.imageType == .stillImage || item.asset.imageType == .livePhoto || item.asset.imageType == .burst || item.asset.mediaType == .video
    }
    
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.modify]
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
        self.updateControllerView()
    }
    
    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original, filtered)
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?) {
        (dockContent as? FiltersAppDockContent)?.selectItem(with: editStateValue)
    }
}

private extension FiltersApp {
    private func updateControllerView() {
        self.dockContent?.view.tintColor = config?.tintColor
    }
}

fileprivate class FiltersAppDockContent: NSObject, KeyPathWatchable, AppDockContent {
    private struct PhotosFilterNames {
        static let CIPhotoEffectChrome = "CIPhotoEffectChrome"
        static let CIPhotoEffectFade = "CIPhotoEffectFade"
        static let CIPhotoEffectInstant = "CIPhotoEffectInstant"
        static let CIPhotoEffectNoir = "CIPhotoEffectNoir"
        static let CIPhotoEffectProcess = "CIPhotoEffectProcess"
        static let CIPhotoEffectTonal = "CIPhotoEffectTonal"
        static let CIPhotoEffectTransfer = "CIPhotoEffectTransfer"
        
        static func aliasName(_ filterName: String) -> String? {
            return CIFilter.localizedName(forFilterName: filterName)?.remove("Photo Effect")
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
    
    private lazy var items: [AppUICollectionView.CollectionItem] = {
        let image = R.image.filtersJpg()
        
        var items = [AppUICollectionView.CollectionItem]()
        
        items.append(AppUICollectionView.CollectionItem(title: "Original".localized, image: image, action: {
            let filterItem = CIFilterItem(CIFilter())
            AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.filter = filterItem
        }))
        
        items += CIFilters.filters.map({ (filter) -> AppUICollectionView.CollectionItem in
            return AppUICollectionView.CollectionItem(title: PhotosFilterNames.aliasName(filter.name), image: image?.applyFilter(ciFilter: filter), action: {
                let filterItem = CIFilterItem(filter)
                AppCenter.default.currentInstanceAs(FiltersApp.self)?.config?.filter = filterItem
            })
        })
        
        return items
    }()
    
    lazy var view: UIView = {
        let view = AppUICollectionView(items: items)
        view.cellSize = CGSize(width: 80, height: 120)
        view.cellSpacing = 2
        view.cellImageInsets = UIEdgeInsetsMake(0, 0, 4, 0)
        
        return view
    }()
    
    func selectItem(with editStateValue: ImageEditStateValue?) {
        let index = items.index(where: { $0.title == PhotosFilterNames.aliasName(editStateValue?.ciFilter?.name ?? "") }) ?? 0
        
        (view as? AppUICollectionView)?.selectItem(at: IndexPath(item: index, section: 0), animated: true)
    }
    
    var preferences: AppDockContentPreferable? {
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 120
        return preferences
    }
    
    func willSetContentView(_ view: UIView, dock: AppDock) {
        
    }
    
    func didSetContentView(_ view:UIView, dock:AppDock) {
        
    }
}

private class _FiltersAppTask: AppTaskPrototypeDefaultConcurrencyCountPolicy, AppTaskable {
    public typealias ParamType = _FiltersAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _FiltersAppAsset)?.cancelAllRequestIDs()
        (param as? _FiltersAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _FiltersAppAsset, "TaskParamable type of this app is \(_FiltersAppAsset.self)")
        guard let _param = param as? _FiltersAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _FiltersAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            assetItem.runEditing({ (progress) in
                PHAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
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
