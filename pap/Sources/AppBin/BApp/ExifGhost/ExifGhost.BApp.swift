//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO
import PropertyKit
private typealias ParamType = AppAsset

public class ExifGhostApp: NSObject, PropertyWatchable,BApp,
        PHAssetFinalizableApp,
        PhotoPickerViewControllerAppearanceDelegatableApp,
        PhotoPickerCollectionViewDelegatableApp,
        AppDockApp,
        PreheatableApp {

    public static let taskType: AppTaskable.Type = _ExifGhostAppTask.self

    public static let paramType: AppTaskParamable.Type = ParamType.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.exifghost"
            , version: "1.0"
            , phase: .release
            , appType: ExifGhostApp.self
            , displayName: "EXIF Ghost"
            , description: "EXIF Ghost lets you remove all kinds of data containing your photos including private information.".localized
            , keywords: ["privacy", "exif", "metadata", "GPS", "altitude", "latitude", "time stamp", "date", "date time", "time", "personal data"]
            , iconBundleName: R.image.exifGhostBAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public private(set) lazy var content: AppDockContent? = ExifGhostAppDockContent()

    @objc dynamic
    public var autoSelect: Bool = false

    public required override init() {
        super.init()
    }

    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.showActions]
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    public func performPreheating(item: PHAssetParamable,  _ async: AsyncWaitSignalable)  -> PreheatingFinishAction? {

        if autoSelect && item.asset.mediaType == .image{
            (content as? PreheatableAppSubscribable)?.didStartPreheating()

            var purged = false
            async.begin()
            PHImageManager.default().requestImageData(for: item.asset, options: nil) { data, s, orientation, dictionary in
                purged = true == data?.getMetadata()?.isPurgedMetadata(for: ImageMetadata.Collection.DefaultSensitivity)
                async.end()
            }
            if async.began{
                async.waitUntilEnd()
            }
            return purged ? nil : UICollectionViewPreheatableAppFinishAction.selectItem
        }

        return nil
    }

    public func didCancelPreheating() {
        (content as? PreheatableAppSubscribable)?.didStopPreheating()
    }

    public func didFinishCurrentPreheatingCycle() {
        (content as? PreheatableAppSubscribable)?.didStopPreheating()
    }

    public var doneButtonTitle: String?{
        return "Hide".localized
    }

    public var titleWillBegin:String? {
        return "Hiding Selected Items...".localized
    }
}

private class _ExifGhostAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncWaitSignalable){
        (param as? ParamType)?.cancelAllRequestIDs()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncWaitSignalable) throws -> AppTaskResultable? {
        guard let param = param as? ParamType else{
            throw AppTaskError.invalidParam
        }

        var result: PHAssetResultItem?

        async.begin()
        let option = PHContentEditingInputRequestOptions()
        option.isNetworkAccessAllowed = true
        option.canHandleAdjustmentData = { _ -> Bool in
            return true
        }

        let id = param.requestContentEditing(options:option) { item in

            assert(item?.input.fullSizeImageURL != nil, "item.input.fullSizeImageURL is nil")
            if let item = item, let url = item.input.fullSizeImageURL{

                if let data = try? Data(contentsOf: url)
                , let metadata = data.getMetadata(){

                    var ghostedData:Data
                    if let appContentAsExifGhostApp = AppCenter.default.currentInstanceAs(AppDockApp.self)?.content as? ExifGhostAppDockContent {
                        if appContentAsExifGhostApp.shouldGhostAll{
                            ghostedData = data.setMetadata(with: nil)

                        }else{
                            ghostedData = data.purgeMetadata(with: metadata, for: appContentAsExifGhostApp.ghostedImageMetadataCollection)
                        }
                    }else{
                        ghostedData = data.setMetadata(with: nil)
                    }

                    do{
                        try ghostedData.write(to: item.output.renderedContentURL, options: .atomic)
                        result = PHAssetResultItem(asset:param.asset, contentEditingOutput:item.output)
                    }catch _ {}
                }

            }

            async.end()
        }

        param.appendRequestId(PHAssetRequestID(forEditingInput: id))

        async.waitUntilEnd()
        return result
    }

}

import Intents

extension ExifGhostApp:UIApplicationDelegateLaunchableApp{
    static var intents: [INIntent] {
        if #available(iOS 12.0, *) {
            let openAppIntent = OpenEXIFGhostIntent()
            openAppIntent.appId = ExifGhostApp.info.identifier
            openAppIntent.appName = NSString.deferredLocalizedIntentsString(with: ExifGhostApp.info.displayName) as String
            openAppIntent.suggestedInvocationPhrase = "Open EXIF Ghost.".localized
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
