//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public protocol PHAssetParamable: TaskParamable{
    var asset: PHAsset { get }
    var indexPath:IndexPath? { set get }
    var requestIDs:[PHAssetRequestID] { get }

    init(_ asset: PHAsset)
    init(_ asset: PHAsset, indexPath:IndexPath)
}

public protocol PHAssetResultable: TaskResultable{
    var asset: PHAsset { get }
    var contentEditingOutput: PHContentEditingOutput?  { get }
}

public struct PHAssetResultItem: PHAssetResultable {
    public var asset: PHAsset
    public var contentEditingOutput: PHContentEditingOutput?
}

public class PHAssetItem<EditStateValueType:Hashable>: ItemObject, PHAssetParamable {
    public var asset: PHAsset
    public var indexPath:IndexPath?
    public var requestIDs = [PHAssetRequestID]()
    public var editState = StateValueSet<EditStateValueType>()

    required public init(_ asset: PHAsset) {
        self.asset = asset
    }

    convenience required public init(_ asset: PHAsset, indexPath:IndexPath) {
        self.init(asset)
        self.indexPath = indexPath
    }
}

public class PHAssetRequestID {
    enum DefaultValue{
        static let forImage = PHInvalidImageRequestID
        static let forResourceData = PHInvalidAssetResourceDataRequestID
        static let forEditingInput = Int.min
    }

    var forImage:PHImageRequestID
    var forResourceData:PHAssetResourceDataRequestID
    var forEditingInput:PHContentEditingInputRequestID

    init(forImage: PHImageRequestID = DefaultValue.forImage,
         forResourceData: PHAssetResourceDataRequestID = DefaultValue.forResourceData,
         forEditingInput: PHContentEditingInputRequestID = DefaultValue.forEditingInput) {

        self.forImage = forImage
        self.forResourceData = forResourceData
        self.forEditingInput = forEditingInput
    }
}
