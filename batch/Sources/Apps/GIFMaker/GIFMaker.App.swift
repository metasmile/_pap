//
//  GIFMaker.App.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 4. 23..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

class _GIFMakerAppAsset: PHAssetItem<ImageEditStateValue> {
    func cancelProcessing() {
        
    }
}

public class GIFMakerAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?
    
//    @objc dynamic
//    public var filter: AppValue?
    
    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }
        
//        if let other = fromOther as? PhotosFilterAppConfig, let filter = other.filter{
//            self.filter = filter
//        }
    }
}

public class GIFMaker: BatchApp, ConfigurableApp, _ConfigurableApp,
    AppDockControllableApp, PHAssetFinalizableApp, PhotoPickerCollectionViewDisplayableApp,
PhotoPickerViewControllerDelegatableApp {
    public static let taskType:Taskable.Type = _GIFMakerAppTask.self
    public static let paramType:TaskParamable.Type = _GIFMakerAppAsset.self
    
    public static var configure:(() -> GIFMakerAppConfig)?
    
    @objc dynamic
    public private(set) lazy var config: GIFMakerAppConfig? = GIFMaker.configure?()
    public private(set) lazy var controller: AppDockContent? = createController()
    
    public static let info = AppInfo(
        identifier: "com.stells.batch.gifmaker"
        , version: "0.1"
        , phase: .beta
        , appType: GIFMaker.self
        , displayName: "GIF Maker"
        , icon: R.image.photosFilterAppIcon.name
        , policy: AppPolicy.default
        , minOSVersion: nil
    )
    
    required public init() {}
    
    public var doneButtonTitle: String? {
        return "Make".localized
    }
    
    public func shouldSelect(item: PHAssetItem<ImageEditStateValue>) -> Bool {
        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return true }
        return firstItem.asset.mediaType == item.asset.mediaType
    }
    
    public var numberOfItemsShouldSelect: Int? {
        guard let firstItem = AppAssets.selected.at(unsafeIndex: 0) else { return nil }
        if firstItem.asset.mediaType == .video || (firstItem.asset.mediaType == .image && firstItem.asset.mediaSubtypes.contains(.photoLive)) {
            return 1
        }
        else {
            return 100
        }
    }
    
    public var finalizingOptions: [PHAssetFinalizingOption]{
        return [.create]
    }
    
    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
    }
    
    private func createController() -> AppDockContent {
        let items = [
            BAppUICollectionView.CollectionItem(title: nil, image: R.image.flipVertical()?.withRenderingMode(.alwaysTemplate), action: nil)
        ]
        
        let view = BAppUICollectionStackView(items: items)
        var preferences = AppDockContentPreferences()
        preferences.pinned = true
        preferences.minimumHeight = 44
        return AppDockContentItem(view: view, preferences: preferences)
    }
}

private class _GIFMakerAppTask: TaskPrototype, Taskable {
    public typealias ParamType = _GIFMakerAppAsset
    public typealias ResultType = PHAssetResultItem
    
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        
        (param as? _GIFMakerAppAsset)?.cancelAllRequestIDs()
        (param as? _GIFMakerAppAsset)?.cancelProcessing()
    }
    
    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        assert(param is _GIFMakerAppAsset, "TaskParamable type of this app is \(_PhotosFilterAppAsset.self)")
        guard let _param = param as? _GIFMakerAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }
    
    private func _perform(_ assetItem: _GIFMakerAppAsset, _ async: AsyncManualSignalable?) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?
        
//        async?.begin()
//
//        assetItem.runEditing({ (progress) in
//            guard let progress = progress else { return }
//            NotificationCenter.default.post(name: PHAssetProcessableNotification.Name.progressChanged, object: self, userInfo: [
//                PHAssetProcessableNotification.UserInfo.Key.progress: progress,
//                PHAssetProcessableNotification.UserInfo.Key.assetItem: assetItem
//                ])
//        }) { (asset, contentEditingOutput) in
//            if let asset = asset, let contentEditingOutput = contentEditingOutput {
//                result = PHAssetResultItem(
//                    asset: asset,
//                    contentEditingOutput: contentEditingOutput)
//            }
//            async?.end()
//        }
//
//        async?.waitUntilEnd()
        return result
    }
}
