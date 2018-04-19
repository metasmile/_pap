//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO


//FIXME: some normal photo fires "NSCocoaErrorDomain 18446744073709551615"

//TODO:
/*
use flow

try
-> share vc
-> save or share
-> remove original? Image itself will be equal. Its quality has not affected.
-> yes -> remove
-> no -> modify


data

- OR operation for all metadata keys in selected photos
- AND operation for handling with EXIFGhost
*/

private typealias ParamType = PHAssetItem<AppValue>

public class ExifGhost: App, PHAssetFinalizableApp,
        PhotoPickerCollectionViewDisplayableApp, AppDockControllableApp,
        PersistableApp {

    public static let taskType:Taskable.Type = _ExifGhostTask.self

    public static let paramType:TaskParamable.Type = ParamType.self

    public static let info = AppInfo(
            identifier: "com.stells.batch.exifghost"
            , version: "0.1"
            , phase: .develop
            , appType: ExifGhost.self
            , displayName: "EXIF Ghost"
            , icon: nil
            , policy: AppPolicy.default
            , minOSVersion: nil
    )

    public private(set) lazy var controller: AppDockContent? = ExifGhostAppDockContent()

    public required init() {}

    public var finalizingOptions: [PHAssetFinalizingOption]{
        return [.share, .delete]
    }

    public func shouldSelect(item: PHAssetItem<AppValue>) -> Bool {
        return item.asset.mediaType == .image
    }
}

private class _ExifGhostTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        (param as? ParamType)?.cancelAllRequestIDs()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        guard let param = param as? ParamType else{
            throw TaskError.invalidParam
        }

        var result: PHAssetResultItem?

        async?.begin()
        let option = PHContentEditingInputRequestOptions()
        option.isNetworkAccessAllowed = true
        option.canHandleAdjustmentData = { _ -> Bool in
            return true
        }

        let id = param.requestContentEditing(options:option) { item in

            assert(item?.input.fullSizeImageURL != nil, "item.input.fullSizeImageURL is nil")
            if let item = item, let url = item.input.fullSizeImageURL{

                let data = try! Data(contentsOf: url)

                if let metadata = data.getMetadata(){

                    var ghostedData:Data

                    if let appContentAsExifGhost = AppCenter.default.currentInstanceAs(AppDockControllableApp.self)?.controller as? ExifGhostAppDockContent
                       , let ghostedImageMetadataCollection = appContentAsExifGhost.ghostedImageMetadataCollection {

                        ghostedData = data.purgeMetadata(with: metadata, for: ghostedImageMetadataCollection)
                    }else{
                        ghostedData = data.purgeMetadata(with: metadata, for: ImageMetadata.Collection.DefaultSensitivity)
                    }

                    try! ghostedData.write(to: item.output.renderedContentURL, options: .atomic)

                    result = PHAssetResultItem(asset:param.asset, contentEditingOutput:item.output)
                }

            }
            async?.end()
        }

        param.requestIDs += [PHAssetRequestID(forEditingInput: id)]

        async?.waitUntilEnd()
        return result
    }

}

