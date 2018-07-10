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

public class TransformAppConfigValue: NSObject, KeyPathWatchable, AppConfigUIAttrributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?

    @objc dynamic
    public var transform: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttrributeValuable {
            self.tintColor = other.tintColor
        }

        if let other = fromOther as? TransformAppConfigValue, let transform = other.transform{
            self.transform = transform
        }
    }
}

public class TransformApp: NSObject, BApp, KeyPathWatchable
        , ConfigurableApp, _ConfigurableApp, PreviewableApp, AppDockApp, PHAssetFinalizableApp
        , PhotoPickerViewControllerDelegatableApp, PhotoPickerCollectionViewDisplayableApp
        , PhotoEditorViewControllerDelegatableApp {

    public static let taskType: AppTaskable.Type = _TransfromAppTask.self

    public static let paramType: AppTaskParamable.Type = _TransformAppAsset.self

    public static var configure:(() -> TransformAppConfigValue)?

    @objc dynamic
    public private(set) lazy var config: TransformAppConfigValue? = TransformApp.configure?()

    public private(set) lazy var dockContent: AppDockContent? = createController()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = createController()

    public static let info = AppInfo(
            identifier: "com.stells.pap.transform"
            , version: "1.0"
            , phase: .release
            , appType: TransformApp.self
            , displayName: "Transform".localized, description:nil, keywords:nil
            , iconBundleName: R.image.transformBAppIcon.name
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

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.modify]
    }
    
    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.imageType != .animatedGIF
    }
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?) {}
}

private extension TransformApp{
    private func createController() -> AppDockContent {
        let items = [
            AppUICollectionView.CollectionItem(title: nil, image: R.image.flipVertical()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = VerticalFlipTransformItem()
            }),
            AppUICollectionView.CollectionItem(title: nil, image: R.image.flipHorizontal()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = HorizontalFlipTransformItem()
            }),
            AppUICollectionView.CollectionItem(title: nil, image: R.image.rotateLeft()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = RotationTransformItem(degrees: -90)
            }),
            AppUICollectionView.CollectionItem(title: nil, image: R.image.rotateRight()?.withRenderingMode(.alwaysTemplate), action: {
                self.config?.transform = RotationTransformItem(degrees: 90)
            })
        ]
        
        let view = AppUICollectionStackView(items: items)
        view.cellSize = CGSize(width: 44, height: 44)
        view.cellSpacing = 2
        view.cellImageInsets = UIEdgeInsetsMake(8, 10, 10, 10)
        
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 52
        return AppDockContentItem(view: view, preferences: preferences)
    }

    private func updateControllerView(){
        self.dockContent?.view.tintColor = config?.tintColor
    }
}

//TODO: retrictful conforms param type
private class _TransfromAppTask: AppTaskPrototype, AppTaskable {

    public typealias ParamType = _TransformAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncManualSignalable){

        (param as? _TransformAppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncManualSignalable) throws -> AppTaskResultable? {
        assert(param is _TransformAppAsset, "TaskParamable type of this app is \(_TransformAppAsset.self)")
        guard let _param = param as? _TransformAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _TransformAppAsset, _ async: AsyncManualSignalable) throws -> PHAssetResultItem?  {
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
