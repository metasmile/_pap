//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO

private typealias ParamType = PHAssetItem<ImageEditStateValue>

public class ExifGhostApp: NSObject, KeyPathWatchable,BApp,
        PHAssetFinalizableApp,
        PhotoPickerViewControllerDelegatableApp,
        PhotoPickerCollectionViewDisplayableApp,
        AppDockApp,
        PreheatableApp {

    public static let taskType: AppTaskable.Type = _ExifGhostAppTask.self

    public static let paramType: AppTaskParamable.Type = ParamType.self

    public static let info = AppInfo(
            identifier: "com.stells.pap.exifghost"
            , version: "1.0"
            , phase: .release
            , appType: ExifGhostApp.self
            , displayName: "EXIF Ghost", description:nil, keywords:nil
            , iconBundleName: R.image.exifGhostBAppIcon.name
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public private(set) lazy var dockContent: AppDockContent? = ExifGhostAppAppDockContent()

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

    public func performPreheating(item: AppAsset, _ async: AsyncSignal) -> PreheatingFinishAction? {

        if autoSelect && item.asset.mediaType == .image{
            var purged = false
            async.begin()
            PHImageManager.default().requestImageData(for: item.asset, options: nil) { data, s, orientation, dictionary in
                purged = true == data?.getMetadata()?.isPurgedMetadata(for: ImageMetadata.Collection.DefaultSensitivity)
                async.end()
            }
            async.waitUntilEnd()

            return purged ? nil : UICollectionViewPreheatableAppFinishAction.selectItem
        }

        return nil
    }

    public var doneButtonTitle: String?{
        return "Hide".localized
    }

    public var titleWillBegin:String? {
        return "Hiding Selected Items...".localized
    }
}

private class _ExifGhostAppTask: AppTaskPrototype, AppTaskable {
    public func cancel(_ param: AppTaskParamable, _ async: AsyncManualSignalable){
        (param as? ParamType)?.cancelAllRequestIDs()
    }

    public func perform(_ param: AppTaskParamable, _ async: AsyncManualSignalable) throws -> AppTaskResultable? {
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
                    if let appContentAsExifGhostApp = AppCenter.default.currentInstanceAs(AppDockApp.self)?.dockContent as? ExifGhostAppAppDockContent {
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

        param.requestIDs += [PHAssetRequestID(forEditingInput: id)]

        async.waitUntilEnd()
        return result
    }

}

