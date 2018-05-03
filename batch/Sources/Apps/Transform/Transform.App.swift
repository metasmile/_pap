//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import QuartzCore
import Photos
import UIKit
import MobileCoreServices
import Crashlytics
import DefaultsKit

public class TransformAppConfig: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?

    @objc dynamic
    public var transform: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }

        if let other = fromOther as? TransformAppConfig, let transform = other.transform{
            self.transform = transform
        }
    }
}

public class TransformApp: NSObject, BApp, KeyPathWatchable
        , ConfigurableApp, _ConfigurableApp, AppDockControllableApp, PHAssetFinalizableApp
        , PhotoPickerViewControllerDelegatableApp, PhotoPickerCollectionViewDisplayableApp {

    public static let taskType:Taskable.Type = _TransfromAppTask.self

    public static let paramType:TaskParamable.Type = _TransformAppAsset.self

    public static var configure:(() -> TransformAppConfig)?

    @objc dynamic
    public private(set) lazy var config: TransformAppConfig? = TransformApp.configure?()

    public private(set) lazy var dockContent: AppDockContent? = createController()

    public static let info = AppInfo(
            identifier: "com.stells.batch.transform"
            , version: "1.0"
            , phase: .release
            , appType: TransformApp.self
            , displayName: "Transform".localized
            , icon: R.image.transformAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public override init(){
        super.init()

        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateControllerView()
        }
    }

    public func setConfigValues<T: AppConfigValuable>(_ config:T){
        self.config?.adoptValues(fromOther: config)
        self.updateControllerView()
    }

    public var finalizingPresets: [PHAssetFinalizingPresets]? {
        return [.modify]
    }
    
    public func shouldSelect(item: PHAssetItem<ImageEditStateValue>) -> Bool {
        return item.asset.imageType != .animatedGIF
    }
}

private extension TransformApp{
    private func createController() -> AppDockContent {
        let items = [
            BAppUICollectionView.CollectionItem(title: nil, image: R.image.flipVertical()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = VerticalFlipTransformItem()
            }),
            BAppUICollectionView.CollectionItem(title: nil, image: R.image.flipHorizontal()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = HorizontalFlipTransformItem()
            }),
            BAppUICollectionView.CollectionItem(title: nil, image: R.image.rotateLeft()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = RotationTransformItem(degrees: -90)
            }),
            BAppUICollectionView.CollectionItem(title: nil, image: R.image.rotateRight()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = RotationTransformItem(degrees: 90)
            })
        ]
        
        let view = BAppUICollectionStackView(items: items)
        var preferences = AppDockContentPreferences()
        preferences.pinned = true
        preferences.minimumHeight = 44
        return AppDockContentItem(view: view, preferences: preferences)
    }

    private func updateControllerView(){
        self.dockContent?.view.tintColor = config?.tintColor
    }
}

//TODO: retrictful conforms param type
private class _TransfromAppTask: TaskPrototype, Taskable {

    public typealias ParamType = _TransformAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){

        (param as? _TransformAppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        assert(param is _TransformAppAsset, "TaskParamable type of this app is \(_TransformAppAsset.self)")
        guard let _param = param as? _TransformAppAsset else{
            throw TaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _TransformAppAsset, _ async: AsyncManualSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?

        async.begin()

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
            async.end()
        }

        async.waitUntilEnd()
        return result


    }
}
