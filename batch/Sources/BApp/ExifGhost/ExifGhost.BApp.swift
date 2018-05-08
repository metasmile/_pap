//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO

private typealias ParamType = PHAssetItem<ImageEditStateValue>

public class ExifGhost: BApp, PHAssetFinalizableApp, PhotoPickerViewControllerDelegatableApp,
        PhotoPickerCollectionViewDisplayableApp, AppDockControllableApp {

    public static let taskType:Taskable.Type = _ExifGhostTask.self

    public static let paramType:TaskParamable.Type = ParamType.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.exifghost"
            , version: "1.0"
            , phase: .release
            , appType: ExifGhost.self
            , displayName: "EXIF Ghost"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public private(set) lazy var dockContent: AppDockContent? = ExifGhostAppDockContent()

    public required init() {}

    public var finalizingPresets: [PHAssetFinalizingPresets] {
        return [.share]
    }

    public func shouldSelect(item: AppAsset) -> Bool {
        return item.asset.mediaType == .image
    }

    public var doneButtonTitle: String?{
        return "Purge"
    }

    public var titleWillBegin:String? {
        return "Purging selected properties...".localized
    }
}

private class _ExifGhostTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable){
        (param as? ParamType)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable) throws -> TaskResultable? {
        guard let param = param as? ParamType else{
            throw TaskError.invalidParam
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
                    if let appContentAsExifGhost = AppCenter.default.currentInstanceAs(AppDockControllableApp.self)?.dockContent as? ExifGhostAppDockContent {
                        if appContentAsExifGhost.shouldGhostAll{
                            ghostedData = data.setMetadata(with: nil)

                        }else{
                            ghostedData = data.purgeMetadata(with: metadata, for: appContentAsExifGhost.ghostedImageMetadataCollection)
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

