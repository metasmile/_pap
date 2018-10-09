//
//  PhotosYouArt.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 3. 28..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import PropertyKit
import Intents

protocol YouArtAppDefaults: AppDefaults {
    var youArtFilterName: String? { get set }
}

extension Defaults: YouArtAppDefaults {
    var youArtFilterName: String? {
        get {
            return get(or: nil)
        }
        
        set { set(newValue); papLog.app.defaults.log(value:newValue ?? "Original") }
    }
}
 

public class YouArtAppConfigValue: NSObject, PropertyWatchable, AppConfigUIAttributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
    @objc dynamic
    public var filter: ImageEditStateValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttributeValuable {
            self.tintColor = other.tintColor
        }
        
        if let other = fromOther as? YouArtAppConfigValue, let filter = other.filter{
            self.filter = filter
        }
    }
}

public class YouArtApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
        PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp,
PhotoEditorViewControllerDelegatableApp, ChargeableApp {

    public static let taskType: AppTaskable.Type = _YouArtAppTask.self
    public static let paramType: AppTaskParamable.Type = _YouArtAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = YouArtAppConfigValue()
        config.tintColor = .black
        return config
    }

    static var localCharges: [Charge] {
        return self.defaultFreeBAppLocalCharges
    }

    @objc dynamic
    public private(set) lazy var config: YouArtAppConfigValue? = type(of:self).defaultConfigValue as? YouArtAppConfigValue

    public private(set) lazy var content: AppDockContent? = YouArtAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = YouArtAppDockContent()
    
    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditStateValue(_ editStateValue: ImageEditStateValue?) {
        defaultEditStateValue = editStateValue
        
        var defaults = type(of: self).defaults as! YouArtAppDefaults
        defaults.youArtFilterName = editStateValue?.ciFilter?.name
    }

    public static let info = AppInfo(
        identifier: "com.stells.pap.youart"
        , version: "1.0"
        , phase: .develop
        , appType: YouArtApp.self
        , displayName: "YouArt"
        , description: "Apply High-Quality filters on your all photos you want. This batch processing tool has no limit to the number of photos to apply filters.".localized
        , keywords: ["YouArt", "Color", "Effect", "High-Quality"]
        , iconBundleName: R.image.youArtBAppIcon.name
        , themeColor: nil
        , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
        , minOSVersion: nil
    )
    
    required public override init() {
        super.init()
        
        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateControllerView()
        }
        
        if let controllerContent = self.content as? YouArtAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! YouArtAppDefaults
                    let filterItem = controllerContent.getYouArtItem(by: defaults.youArtFilterName)
                    self.config?.filter = filterItem
                    self.defaultEditStateValue = filterItem
                }
            }
        }
        
        if let controllerContent = self.photoEditorDockContent as? YouArtAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! YouArtAppDefaults
                    let filterItem = controllerContent.getYouArtItem(by: defaults.youArtFilterName)
                    self.config?.filter = filterItem
                }
            }
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

    public static var fixedContentLayout: Bool {
        return true
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
    
    public func photoEditorWillBeginProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = false
    }
    
    public func photoEditorWillEndProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = true
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {
        (content as? YouArtAppDockContent)?.selectItem(with: editStateValue)
    }
}
//
//extension YouArtApp:UIApplicationDelegateLaunchableApp{
//    static var intents: [INIntent] {
//        if #available(iOS 12.0, *) {
//            let openAppIntent = OpenYouArtIntent()
//            openAppIntent.appId = YouArtApp.info.identifier
//            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: YouArtApp.info.displayName) as String
//            openAppIntent.suggestedInvocationPhrase = "Open YouArt.".localized
//            return [openAppIntent]
//        } else {
//            return []
//        }
//    }
//
//    func didLaunchHandling(with userActivity: NSUserActivity) {
//
//    }
//
//    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
//    }
//}


private extension YouArtApp {
    private func updateControllerView() {
        self.content?.view.tintColor = config?.tintColor
        self.photoEditorDockContent?.view.tintColor = config?.tintColor
    }
}

fileprivate class YouArtAppDockContent: NSObject, PropertyWatchable, AppDockContent {
    private lazy var filters: [CIFilter] = [
        CIMLArtFilter(style: MLArtStyle.Mosaic),
        CIMLArtFilter(style: MLArtStyle.Candy),
        CIMLArtFilter(style: MLArtStyle.Feathers),
        CIMLArtFilter(style: MLArtStyle.Muse),
        CIMLArtFilter(style: MLArtStyle.Udanie),
        CIMLArtFilter(style: MLArtStyle.Scream)
    ]

    @objc dynamic var filterItem: CIFilterItem?

    private lazy var items: [AppUICollectionView.CollectionItem] = {
        let image = R.image.filtersJpg()
        
        var items = [AppUICollectionView.CollectionItem]()
        
        items.append(AppUICollectionView.CollectionItem(title: "Original".localized, image: image, action: {
            self.filterItem = CIFilterItem()
        }))
        
        items += self.filters.map({ (filter) -> AppUICollectionView.CollectionItem in
            return AppUICollectionView.CollectionItem(title: filter.name, image: image, action: {
                let filterItem = CIFilterItem(filter)
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
    
    fileprivate func getYouArtItem(by filterName: String?) -> CIFilterItem? {
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
                        mutableItem.image = item.image?.applyFilter(ciFilter: s.filters[safe: i-1])
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
}

private class _YouArtAppTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _YouArtAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        
        (param as? _YouArtAppAsset)?.cancelAllRequestIDs()
        (param as? _YouArtAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _YouArtAppAsset, "TaskParamable type of this app is \(_YouArtAppAsset.self)")
        guard let _param = param as? _YouArtAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _YouArtAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
        async.begin()
        
        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: YouArtApp.self, editInfo: ["filterName": assetItem.editState.ciFilter?.name ?? ""], from: asset)
                    
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

