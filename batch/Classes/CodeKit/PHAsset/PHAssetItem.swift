//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public class PHAssetItem: ItemObject {
    var asset: PHAsset
    var indexPath:IndexPath?

    var editItem = TransformEditItem()
    var requestIDs = [PHAssetRequestID]()

    required public init(_ asset: PHAsset) {
        self.asset = asset
    }

    convenience public init(_ asset: PHAsset, indexPath:IndexPath) {
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
