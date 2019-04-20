//
//  PhotosArtist.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 3. 28..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import PropertyKit
import Intents

protocol ArtistAppDefaults: AppDefaults {
    var artistFilterName: String? { get set }
}

extension Defaults: ArtistAppDefaults {
    var artistFilterName: String? {
        get {
            return get(or: nil)
        }

        set { set(newValue); papLog.app.defaults.log(value:newValue ?? "Original") }
    }
}


public class ArtistAppConfigValue: NSObject, PropertyWatchable, AppConfigAdoptableValuable {
    @objc dynamic
    public var filter: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? ArtistAppConfigValue, let filter = other.filter{
            self.filter = filter
        }
    }
}

public class ArtistApp: NSObject, BApp, PropertyWatchable, ConfigurableApp, _ConfigurableApp,
        PHAssetFinalizableApp, EditableApp, PreviewProcessableApp, AppDockApp,
        PhotoPickerCollectionViewDelegatableApp, PhotoPickerViewControllerAppearanceDelegatableApp,
PhotoEditorViewControllerDelegatableApp {

    public static let taskType: AppTaskable.Type = _ArtistAppTask.self
    public static let paramType: AppTaskParamable.Type = _ArtistAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = ArtistAppConfigValue()
        return config
    }

    @objc dynamic
    public private(set) lazy var config: ArtistAppConfigValue? = type(of:self).defaultConfigValue as? ArtistAppConfigValue

    public private(set) lazy var content: AppDockContent? = ArtistAppDockContent()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = ArtistAppDockContent()

    public private(set) var defaultEditStateValue: ImageEditStateValue?
    public func setDefaultEditState(value: ImageEditStateValue?) {
        defaultEditStateValue = value

        var defaults = type(of: self).defaults as! ArtistAppDefaults
        defaults.artistFilterName = value?.ciFilter?.name
    }

    public static let info = AppInfo(
        identifier: "com.stells.batch.artist"
        , version: "1.0"
        , phase: .release
        , appType: ArtistApp.self
        , displayName: "Artist".localized.localizedCapitalized
        , description: "Be an artist. Artist let you dramatically turn your all photos or videos into famous styled paintings. This batch processing tool has no limit to the number of photos to convert.".localized
        , keywords: ["Artist", "Artwork", "Art", "Painting", "Machine Learning", "Art Creation", MLArtStyle.Mosaic.name, MLArtStyle.Muse.name, MLArtStyle.Udanie.name, MLArtStyle.Candy.name, MLArtStyle.Feathers.name, MLArtStyle.Scream.name]
        , iconBundleName: R.image.artistBAppIcon.name
        , themeColor: nil
        , policy: AppPolicy(lifeCycle: AppLifecyclePolicy(instance: .availability), task: AppTaskPolicy.default)
        , minOSVersion: nil
    )

    required public override init() {
        super.init()

        if let controllerContent = self.content as? ArtistAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! ArtistAppDefaults
                    let filterItem = controllerContent.getArtistItem(by: defaults.artistFilterName)
                    self.config?.filter = filterItem
                    self.defaultEditStateValue = filterItem
                }
            }
        }

        if let controllerContent = self.photoEditorDockContent as? ArtistAppDockContent {
            controllerContent.watch(\.filterItem, options: [.initial, .new]) {
                if let filterItem = controllerContent.filterItem {
                    self.config?.filter = filterItem
                }
                else {
                    var defaults = type(of: self).defaults as! ArtistAppDefaults
                    let filterItem = controllerContent.getArtistItem(by: defaults.artistFilterName)
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

    fileprivate var photoPickerCallee:PhotoPickerViewControllerUniversalOperations?

    func didAppear(callee: PhotoPickerViewControllerUniversalOperations) {
        self.photoPickerCallee = callee
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

    public func showsVisibleEffectWhileProcessing() -> Bool {
        return true
    }

    public func photoEditorWillBeginProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = false
    }

    public func photoEditorWillEndProcessing() {
        photoEditorDockContent?.view.isUserInteractionEnabled = true
    }

    public func selectEditState(value: ImageEditStateValue?, in content: AppDockContent?) {
        (content as? ArtistAppDockContent)?.selectItem(with: value)
    }
}
//
//extension ArtistApp:UIApplicationDelegateLaunchableApp{
//    static var intents: [INIntent] {
//        if #available(iOS 12.0, *) {
//            let openAppIntent = OpenArtistIntent()
//            openAppIntent.appId = ArtistApp.info.identifier
//            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: ArtistApp.info.displayName) as String
//            openAppIntent.suggestedInvocationPhrase = "Open %@.".localizedFormatted(defaultAppName)
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

fileprivate extension CIFilter{

    private var cacheFileURL:URL{
        return FileURL.document(name, UTI.png, group: fileName())
    }

    var processedImage:UIImage?{
        set{
            DispatchQueue.global(qos: .background).async{
                try? newValue?.asPNGData?.write(to: self.cacheFileURL)
            }
        }
        get{
            if FileManager.default.fileExists(atPath: self.cacheFileURL.path){
                return UIImage(contentsOfFile: self.cacheFileURL.path)
            }
            return nil
        }
    }
}

fileprivate class ArtistAppDockContent: NSObject, PropertyWatchable, AppDockContent {
    private lazy var filters: [CIFilter] = [
        CIMLArtFilter(style: MLArtStyle.Mosaic),
        CIMLArtFilter(style: MLArtStyle.Candy),
        CIMLArtFilter(style: MLArtStyle.Feathers),
        CIMLArtFilter(style: MLArtStyle.Muse),
        CIMLArtFilter(style: MLArtStyle.Udanie),
        CIMLArtFilter(style: MLArtStyle.Scream)
    ]

    @objc dynamic var filterItem: CIFilterItem?

    fileprivate lazy var items: [AppUICollectionView.CollectionItem] = {
        let image = R.image.filtersJpg()

        var items = [AppUICollectionView.CollectionItem]()

        items.append(AppUICollectionView.CollectionItem(title: "Original".localized, image: image, action: {
            self.filterItem = CIFilterItem()
        }))

        items += self.filters.map({ (filter) -> AppUICollectionView.CollectionItem in
            return AppUICollectionView.CollectionItem(title: filter.name, image: filter.processedImage ?? image, action: {
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
        let index = items.firstIndex(where: { $0.title == filterName ?? "" }) ?? 0
        (view as? AppUICollectionView)?.selectItem(at: IndexPath(item: index, section: 0), animated: true)
    }

    fileprivate func selectItem(with value: ImageEditStateValue?) {
        selectItem(by: value?.ciFilter?.name)
    }

    fileprivate func getArtistItem(by filterName: String?) -> CIFilterItem? {
        let index = items.firstIndex(where: { $0.title == filterName ?? "" }) ?? 0
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
        loadPreview()
    }

    private func loadPreview(){
        DispatchQueue.global().async{ [weak self] in
            guard let s = self else{
                return
            }

            var newlyProcessedAtLeastOne = false
            let renderedItems = s.items.enumerated().map { (i:Int, item:AppUICollectionView.CollectionItem) -> AppUICollectionView.CollectionItem in
                return autoreleasepool{
                    if i == 0{
                        return item
                    }else{
                        var mutableItem = item
                        if let filter = s.filters[safe: i-1]{

                            if filter.processedImage == nil{
                                let appliedImage = item.image?.applyFilter(ciFilter: filter)
                                mutableItem.image = appliedImage

                                filter.processedImage = appliedImage

                                if newlyProcessedAtLeastOne == false{
                                    newlyProcessedAtLeastOne = true
                                }
                            }
                        }
                        return mutableItem
                    }
                }
            }

            if newlyProcessedAtLeastOne{
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
}

private class _ArtistAppTask: AppTaskPrototype, AppTaskable {
    public typealias ParamType = _ArtistAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){

        (param as? _ArtistAppAsset)?.cancelAllRequestIDs()
        (param as? _ArtistAppAsset)?.cancelProcessing()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _ArtistAppAsset, "TaskParamable type of this app is \(_ArtistAppAsset.self)")
        guard let _param = param as? _ArtistAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _ArtistAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?

        async.begin()

        DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, editingResultItems, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: ArtistApp.self, editInfo: ["filterName": assetItem.editState.ciFilter?.name ?? ""], from: asset)

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

extension ArtistApp: UIApplicationDelegateLaunchableApp {
    private static let RepaintRandom = "Repaint the last item with a random art effect.".localized

    static var intents: [INIntent]{

        if #available(iOS 12.0, *) {
            return defaultIntents + [intentTo(do: RepaintRandom)]

        } else{
            return []
        }

    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

        if #available(iOS 12.0, *) {
            guard let intent = userActivity.interaction?.intent else {
                return
            }

            if let i = intent as? DoAnyIntent, let name = i.doWhat{

                if name == type(of: self).RepaintRandom
                    , let items = (content as? ArtistAppDockContent)?.items
                    , let randIndex = (1 ..< items.count).randomElement(){

                    let randomItem = items[randIndex]

                    (content as? ArtistAppDockContent)?.selectItem(by: randomItem.title)

                    DispatchQueue.global(qos: .userInteractive).async{ [unowned self] in

                        //find latest asset with matched converter
                        let foundAsset = PHAssets.fetched.searchLast{ i, a in
                            return self.shouldSelect(item: AppAsset(a))
                        }

                        if let foundAsset = foundAsset{
                            DispatchQueue.main.async{
                                assert(self.photoPickerCallee != nil)
                                self.photoPickerCallee?.selectInCurrentContext(with: foundAsset, animated: true)
                                self.photoPickerCallee?.performInSelectionContext()
                            }
                        }
                    }
                }

            }
        }

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }

}



