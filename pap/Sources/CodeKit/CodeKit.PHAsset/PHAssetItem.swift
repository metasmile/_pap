//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public protocol PHAssetParamable: AppTaskParamable {
    var asset: PHAsset { get }
    var indexPath:IndexPath? { set get }
    var requestIDs:[PHAssetRequestID] { get }

    init(_ asset: PHAsset)
    init(_ asset: PHAsset, indexPath:IndexPath?)
}

public protocol PHAssetResultable: AppTaskResultable {
    var asset: PHAsset { get }
    var contentEditingOutput: PHContentEditingOutput?  { get }
}

public struct PHAssetResultItem: PHAssetResultable {
    public var asset: PHAsset
    public var contentEditingOutput: PHContentEditingOutput?

    init(asset:PHAsset, contentEditingOutput:PHContentEditingOutput?=nil){
        self.asset = asset
        self.contentEditingOutput = contentEditingOutput
    }
}


public struct PHAssetItemProgressNotification {
    static func update(item: PHAssetItem<ImageEditStateValue>?=nil, progress: Progress) {
        var userInfo: [String: Any] = [
            PHAssetProgressNotification.UserInfo.Key.progress: Float(progress.fractionCompleted)
        ]

        if let assetItem = item {
            userInfo[PHAssetProgressNotification.UserInfo.Key.assetItem] = assetItem
        }

        NotificationCenter.default.post(name: PHAssetProgressNotification.Name.progressChanged, object: self, userInfo: userInfo)
    }
}

//TODO: Minifiy 2-depth generic type/protocolize
public class PHAssetItem<EditStateValueType:Hashable>: ItemObject, PHAssetParamable {
    public var asset: PHAsset
    public var indexPath:IndexPath?
    public var requestIDs = [PHAssetRequestID]()
    public var editState = StateValueSet<EditStateValueType>()

    required public init(_ asset: PHAsset) {
        self.asset = asset
    }

    convenience required public init(_ asset: PHAsset, indexPath:IndexPath?=nil) {
        self.init(asset)
        self.indexPath = indexPath
    }

    public class func create(for asset: PHAsset, manager:AppManager=AppCenter.default) -> PHAssetItem<EditStateValueType>? {
        guard let app = manager.current else { return nil }

        if let itemType = app.paramType as? PHAssetParamable.Type
        , let item = itemType.init(asset) as? PHAssetItem<EditStateValueType> {
            return item

        } else{
            assert(false, "[!] Unable to create, or does not implement yet for param type of \(app.info.appType)")
            return nil
        }
    }
}

public struct PHAssetRequestID {
    enum DefaultValue{
        static let forImage = PHInvalidImageRequestID
        static let forResourceData = PHInvalidAssetResourceDataRequestID
        static let forEditingInput = Int.min
    }

    private(set) var forImage:PHImageRequestID = DefaultValue.forImage
    private(set) var forResourceData:PHAssetResourceDataRequestID = DefaultValue.forResourceData
    private(set) var forEditingInput:PHContentEditingInputRequestID = DefaultValue.forEditingInput

    init(forImage: PHImageRequestID) {
        self.forImage = forImage
    }

    init(forResourceData: PHAssetResourceDataRequestID) {
        self.forResourceData = forResourceData
    }

    init(forEditingInput: PHContentEditingInputRequestID) {
        self.forEditingInput = forEditingInput
    }
}
