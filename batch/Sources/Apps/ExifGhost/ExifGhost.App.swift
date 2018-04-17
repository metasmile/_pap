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
try
-> share vc
-> save or share
-> remove original? Image itself will be equal. Its quality has not affected.
-> yes -> remove
-> no -> modify
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

//                do{

                    let data = try! Data(contentsOf: url)

                    if let metadata = data.getMetadata(){

                        for k in metadata[kCGImagePropertyExifDictionary as String] as! [String:Any]{
                            if ImageMetadataProperties.Raw.EXIF.contains(k.key){
                                print(ImageMetadataProperties.Raw.EXIF.index(of: k.key)!, k.key)
                            }
                        }

                        print("-------------------------")

                        for k in metadata[kCGImagePropertyGPSDictionary as String] as! [String:Any]{
                            if ImageMetadataProperties.Raw.GPS.contains(k.key){
                                print(ImageMetadataProperties.Raw.GPS.index(of: k.key)!, k.key)
                            }
                        }

                        print("-------------------------")

                        let newMetadata = metadata.removeGeoTag()
                        let processedData = data.setMetadata(with: newMetadata)
//                        let processedData = data.changeMetadata(metadata: metadata.removeGeoTag(), imageSize: nil, comment: nil, software: nil, exifOrientation: nil)

                        try! processedData.write(to: item.output.renderedContentURL, options: .atomic)

                        result = PHAssetResultItem(asset:param.asset, contentEditingOutput:item.output)
                    }


//                }catch let e {
//                    print("------------",e)
//                }
            }
            async?.end()
        }

//        let id = param.requestContentEditing { item in
//
//            if let item = item
//            , let image = item.input.fullSizeImageURL?.asCIImage{
//                var metadata = image.properties
//
//                if metadata[kCGImagePropertyGPSDictionary as String] != nil {
//
//                    //TODO: remove key from configuration
//                    metadata.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
//
//                    // set and write image file with new metadata from conf
//                    if image.settingProperties(metadata).writeJPEGRepresentation(to: item.output.renderedContentURL){
//                        result = PHAssetResultItem(asset:param.asset, contentEditingOutput:item.output)
//                    }
//
//                    #if DEBUG
//                    if let testResult = item.output.renderedContentURL.asCIImage?.properties{
//                        let diff = Set(image.properties.keys).subtracting(Set(testResult.keys))
//
//                        assert(diff.count==1)
//                        assert(diff.first == kCGImagePropertyGPSDictionary as String)
//                    }
//                    #endif
//                }
//            }
//
//            async?.end()
//        }

        param.requestIDs += [PHAssetRequestID(forEditingInput: id)]

        async?.waitUntilEnd()
        return result
    }
}

