//
//  PhotosFilter.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 3. 28..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import Intents

protocol FilterAppDefaults: AppDefaults {
    var filterName: String? { get set }
}

extension Defaults: FilterAppDefaults {
    var filterName: String? {
        get {
            return get(or: nil)
        }

        set { set(newValue); papLog.app.defaults.log(value:newValue ?? "Original") }
    }
}

public class FiltersAppConfigValue: NSObject, PropertyWatchable, AppConfigAdoptableValuable {
    @objc dynamic
    public var filter: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? FiltersAppConfigValue, let filter = other.filter{
            self.filter = filter
        }
    }
}

public class FiltersApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
        PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp,
PhotoEditViewControllerDelegatableApp {

    public static let taskType: AppTaskable.Type = _FiltersAppTask.self
    public static let paramType: AppTaskParamable.Type = _FiltersAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = FiltersAppConfigValue()
        return config
    }

    @objc dynamic
    public private(set) lazy var config: FiltersAppConfigValue? = type(of:self).defaultConfigValue as? FiltersAppConfigValue

    public private(set) lazy var content: AppDockContent? = FiltersAppDockContent()
    public private(set) lazy var editViewDockContent: AppDockContent? = FiltersAppDockContent()

    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditState(value: ImageEditStateValue?) {
        defaultEditStateValue = value

        var defaults = type(of: self).defaults as! FilterAppDefaults
        defaults.filterName = value?.ciFilter?.name
    }

    public static let info = AppInfo(
        identifier: "com.stells.batch.filters"
        , version: "1.0"
        , phase: .release
        , appType: FiltersApp.self
        , displayName: "Filters".localized.localizedCapitalized
        , description: "Apply High-Quality filters on your all photos you want. This batch processing tool has no limit to the number of photos to apply filters.".localized
        , keywords: ["Filters", "Color", "Effect", "High-Quality"] + FiltersAppDockContent.CIFilters.filters.compactMap({ FiltersAppDockContent.PhotosFilterNames.aliasName($0.name) })
        , icon: AppIcon(source: R.image.filtersBAppIcon.name, style: .original)
        , themeColor: nil, policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
        , minOSVersion: nil
    )

    required public override init() {
        super.init()
        // watch initialization stubbed
    }

    public var doneButtonTitle: String? {
        return "Apply".localized
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

    public func previewProcessing(_ appAsset: AppAsset, targetSize: CGSize, in content: AppDockContent?, completion: @escaping ((_ original: UIImage?, _ filtered: UIImage?) -> Void)) {
        let original = appAsset.asset.requestThumbnailImage(targetSize: targetSize)
        let filtered = original?.applyFilter(ciFilter: appAsset.editState.ciFilter)
        completion(original, filtered)
    }

    public func willBeginProcessing() {
        editViewDockContent?.view.isUserInteractionEnabled = false
    }

    public func willEndProcessing() {
        editViewDockContent?.view.isUserInteractionEnabled = true
    }

    public func selectEditState(value: ImageEditStateValue?, in content: AppDockContent?) {
        (content as? FiltersAppDockContent)?.selectItem(with: value)
    }
}

extension FiltersApp:UIApplicationDelegateLaunchableApp{}

fileprivate class FiltersAppDockContent: NSObject, PropertyWatchable, AppDockContent {
    fileprivate struct PhotosFilterNames {
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
            self.filterItem = CIFilterItem()
        }))

        items += CIFilters.filters.map({ (filter) -> AppUICollectionView.CollectionItem in
            return AppUICollectionView.CollectionItem(title: PhotosFilterNames.aliasName(filter.name), image: image?.applyFilter(ciFilter: filter), action: {
                let filterItem = CIFilterItem(filter)
                self.filterItem = filterItem
            })
        })

        return items
    }()

    lazy var view: UIView = {
        let view = AppUICollectionView(items: items)
        view.cellAppearance.size = CGSize(width: 80, height: 120)
        view.cellAppearance.spacing = 2
        view.cellAppearance.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)

        return view
    }()

    var selectedEditStateValue: ImageEditStateValue?

    fileprivate func selectItem(by filterName: String?) {
        let index = items.firstIndex(where: { $0.title == PhotosFilterNames.aliasName(filterName ?? "") }) ?? 0
        (view as? AppUICollectionView)?.selectItem(at: IndexPath(item: index, section: 0), animated: true)
    }

    fileprivate func selectItem(with value: ImageEditStateValue?) {
        selectItem(by: value?.ciFilter?.name)
    }

    fileprivate func getFilterItem(by filterName: String?) -> CIFilterItem? {
        let index = items.firstIndex(where: { $0.title == PhotosFilterNames.aliasName(filterName ?? "") }) ?? 0
        return CIFilterItem(CIFilters.filters[safe: index - 1])
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

        loadPreview()
    }


    private func loadPreview(){
        DispatchQueue.global().async{ [weak self] in
            guard let s = self else{
                return
            }

            let renderedItems = s.items.enumerated().map { (i:Int, item:AppUICollectionView.CollectionItem) -> AppUICollectionView.CollectionItem in
                return autoreleasepool{
                    if i == 0{
                        return item
                    }else{
                        var mutableItem = item
                        mutableItem.image = item.image?.applyFilter(ciFilter: CIFilters.filters[safe: i-1])
                        return mutableItem
                    }
                }
            }

            DispatchQueue.main.async{
                UIView.transition(with: s.view,
                        duration: 0.35,
                        options: .transitionCrossDissolve,
                        animations: {
                            (s.view as? AppUICollectionView)?.reloadData(items:renderedItems)
                        })

            }
        }
    }

    @objc dynamic var filterItem: CIFilterItem?
}

private class _FiltersAppTask: AppTaskPrototype, AppTaskable {
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

        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: FiltersApp.self, editInfo: ["filterName": assetItem.editState.ciFilter?.name ?? ""], from: asset)

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

