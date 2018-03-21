//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO

// Location
// Date
// ... Option to remove
// All

private typealias ParamType = PHAssetItem<AppValue>

//TODO: PHAssetEditableFinalizableApp.finalize -> fix Error Domain=NSCocoaErrorDomain Code=-1 "(null)"
public class ExifGhost: App, PHAssetEditableFinalizableApp {
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
    )

    public required init() {}
}

private class _ExifGhostTask: TaskPrototype, Taskable {
    public func cancel(_ param:TaskParamable, _ async: AsyncManualSignalable?){
        (param as? ParamType)?.cancelEditing()
    }

    public func perform(_ param: TaskParamable, _ async: AsyncManualSignalable?) throws -> TaskResultable? {
        guard let param = param as? ParamType else{
            throw TaskError.invalidParam
        }

        var result: PHAssetResultItem?

        async?.begin()

        let id = param.requestContentEditing { item in

            if let item = item
            , let image = item.input.fullSizeImageURL?.asCIImage{
                var metadata = image.properties

                print(metadata)
                //TODO: configure from configValue
                metadata.removeValue(forKey: kCGImagePropertyGPSDictionary as String)

                let outputData = UIImageJPEGRepresentation(UIImage(ciImage: image.settingProperties(metadata)), 1)

                guard (try? outputData?.write(to: item.output.renderedContentURL, options: .atomic)) != nil else {
                    return
                }
//                if image.settingProperties(metadata).writeJPEGRepresentation(to: item.output.renderedContentURL){
//                    result = PHAssetResultItem(asset:param.asset, contentEditingOutput:item.output)
//                }

                result = PHAssetResultItem(asset:param.asset, contentEditingOutput:item.output)

                print(item.output.renderedContentURL,item.output.renderedContentURL.asCIImage?.properties)
            }

            async?.end()
        }

        param.requestIDs += [PHAssetRequestID(forEditingInput: id)]

        async?.stopUntilEnd()
        return result
    }
}

