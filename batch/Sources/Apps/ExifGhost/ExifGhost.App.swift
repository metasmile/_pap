//
// Created by BLACKGENE on 19/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import ImageIO

private typealias ParamType = PHAssetItem<AppValue>

public class ExifGhost: App, PHAssetFinalizableApp, ItemCollectableApp, UIControllableApp {
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

    public var finalizingOptions: PHAssetFinalizingOptions{
        return [.delete, .create]
        //return [.modify]
        //TODO: PHAssetEditableFinalizableApp.finalize -> fix Error Domain=NSCocoaErrorDomain Code=-1 "(null)"
    }

    public func areItemsEnables(for: PHAssetItem<AppValue>) -> Bool {
        //TODO: lookup CIImage.properties
        return true
    }
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

                if metadata[kCGImagePropertyGPSDictionary as String] != nil {

                    //TODO: remove key from configuration
                    metadata.removeValue(forKey: kCGImagePropertyGPSDictionary as String)

                    // set and write image file with new metadata from conf
                    if image.settingProperties(metadata).writeJPEGRepresentation(to: item.output.renderedContentURL){
                        result = PHAssetResultItem(asset:param.asset, contentEditingOutput:item.output)
                    }

                    #if DEBUG
                    if let testResult = item.output.renderedContentURL.asCIImage?.properties{
                        let diff = Set(image.properties.keys).subtracting(Set(testResult.keys))

                        assert(diff.count==1)
                        assert(diff.first == kCGImagePropertyGPSDictionary as String)
                    }
                    #endif
                }
            }

            async?.end()
        }

        param.requestIDs += [PHAssetRequestID(forEditingInput: id)]

        async?.stopUntilEnd()
        return result
    }
}

