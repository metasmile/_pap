//
// Created by BLACKGENE on 24/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import QuartzCore
import Photos
import UIKit
import MobileCoreServices
import PropertyKit

public class TransformAppConfigValue: NSObject, PropertyWatchable, AppConfigUIAttributeValuable, AppConfigAdoptableValuable {
    @objc dynamic
    public var tintColor: UIColor?

    @objc dynamic
    public var transform: ImageEditStateValue?

    public func adoptValues(fromOther: AppConfigValuable) {
        if let other = fromOther as? AppConfigUIAttributeValuable {
            self.tintColor = other.tintColor
        }

        if let other = fromOther as? TransformAppConfigValue, let transform = other.transform{
            self.transform = transform
        }
    }
}

public class TransformApp: NSObject, BApp, PropertyWatchable
        , ConfigurableApp, _ConfigurableApp, EditableApp, AppDockApp, PHAssetFinalizableApp
        , PhotoPickerViewControllerAppearanceDelegatableApp, PhotoPickerCollectionViewDelegatableApp
        , PhotoEditorViewControllerDelegatableApp {

    public static let taskType: AppTaskable.Type = _TransfromAppTask.self

    public static let paramType: AppTaskParamable.Type = _TransformAppAsset.self

    public static var defaultConfigValue: AppConfigValuable {
        let config = TransformAppConfigValue()
        config.tintColor = TransformApp.info.themeColor
        return config
    }

    @objc dynamic
    public private(set) lazy var config: TransformAppConfigValue? = type(of:self).defaultConfigValue as? TransformAppConfigValue

    public private(set) lazy var content: AppDockContent? = createController()
    public private(set) lazy var photoEditorDockContent: AppDockContent? = createController()

    public static let info = AppInfo(
            identifier: "com.stells.pap.transform"
            , version: "1.0"
            , phase: .release
            , appType: TransformApp.self
            , displayName: "Rotation".localized.localizedCapitalized
            , description: "This straightforward but large-scale batch image transform tool lets you quickly rotate and flip a lot of media files including Live Photos. There is no limit to the number of photos to edit them.".localized
            , keywords: ["Transformation", "Rotation","Flip","Vertical","Editor"]
            , iconBundleName: R.image.transformBAppIcon.name
            , themeColor: UIColor(red:0.75, green:0.31, blue:0.8, alpha:1)
                        , policy: AppPolicy.default
            , minOSVersion: nil
    )

    required public override init(){
        super.init()

        config?.watch(\.tintColor, options: [.initial, .new]) {
            self.updateControllerView()
        }
    }

    public private(set) var doneButtonTitle: String? = "Rotate".localized

    public static var fixedContentLayout: Bool {
        return true
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
    
    public func selectEditStateValue(_ editStateValue: ImageEditStateValue?, in content: AppDockContent?) {}
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
        view.cellImageInsets = UIEdgeInsets(top: 8, left: 10, bottom: 10, right: 10)
        
        var preferences = AppDockContentPreferences()
        preferences.preferredHeight = 52
        
        let scrollable = AppDockScrollableContent(view.collectionView)
        
        return AppDockContentItem(view: view, preferences: preferences, contentScrollable: scrollable)
    }

    private func updateControllerView(){
        self.content?.view.tintColor = config?.tintColor
        self.photoEditorDockContent?.view.tintColor = config?.tintColor
    }
}

//TODO: retrictful conforms param type
private class _TransfromAppTask: AppTaskPrototype, AppTaskable {

    public typealias ParamType = _TransformAppAsset
    public typealias ResultType = PHAssetResultItem

    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){

        (param as? _TransformAppAsset)?.cancelAllRequestIDs()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        assert(param is _TransformAppAsset, "TaskParamable type of this app is \(_TransformAppAsset.self)")
        guard let _param = param as? _TransformAppAsset else{
            throw AppTaskError.invalidParam
        }
        return try self._perform(_param, async)
    }

    private func _perform(_ assetItem: _TransformAppAsset, _ async: AsyncWaitSignalable) throws -> PHAssetResultItem?  {
        var result: PHAssetResultItem?

        async.begin()

        DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
            assetItem.runEditing({ (progress) in
                AppAssetItemProgressNotification.update(item: assetItem, progress: progress)
            }) { (asset, contentEditingOutput) in
                if let asset = asset, let contentEditingOutput = contentEditingOutput {
                    contentEditingOutput.adjustmentData = PAPAdjustmentData.createAdjustmentData(for: TransformApp.self, editInfo: ["transform": NSCoder.string(for: assetItem.editState.transform)], from: asset)
                    
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

import Intents

extension TransformApp:UIApplicationDelegateLaunchableApp{
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenIntent()
            openAppIntent.appId = TransformApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: TransformApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open Rotation.".localized
            return [openAppIntent]
        } else {
            return []
        }
    }

    func didLaunchHandling(with userActivity: NSUserActivity) {

    }

    func didLaunchHandling(with shortcutItem: UIApplicationShortcutItem) {
    }
}
