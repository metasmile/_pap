//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public protocol PHAssetParamable: AppTaskParamable {
    var asset: PHAsset { get }
    var indexPath:IndexPath? { get }
    var requestIDs:[PHAssetRequestID]? { get }
    var cachingRequestOptions:[PHAssetRequestOption]? { get }

    init(_ asset: PHAsset)
    init(_ asset: PHAsset, indexPath:IndexPath?)
}

public protocol PHAssetResultable: AppTaskResultable {
    var asset: PHAsset { get }
    var contentEditingOutput: PHContentEditingOutput?  { get }
}

public struct PHAssetItem: PHAssetParamable{ //Non-mutable PHAsset VO

    public let asset: PHAsset
    public let indexPath: IndexPath?
    public let requestIDs: [PHAssetRequestID]?
    public let cachingRequestOptions: [PHAssetRequestOption]?

    public init(_ asset: PHAsset) {
        self.init(asset)
    }

    public init(_ asset: PHAsset, indexPath: IndexPath?) {
        self.init(asset,indexPath:indexPath)
    }

    public init(_ asset: PHAsset, indexPath: IndexPath?=nil, requestIDs:[PHAssetRequestID]?=nil, cachingRequestOptions:[PHAssetRequestOption]?=nil) {
        self.asset = asset
        self.indexPath = indexPath
        self.requestIDs = requestIDs
        self.cachingRequestOptions = cachingRequestOptions
    }
}

public struct PHAssetResultItem: PHAssetResultable {
    public var asset: PHAsset
    public var contentEditingOutput: PHContentEditingOutput?

    init(asset:PHAsset, contentEditingOutput:PHContentEditingOutput?=nil){
        self.asset = asset
        self.contentEditingOutput = contentEditingOutput
    }
}

public struct AppAssetItemProgressNotification {
    static func update(item: AppAsset?=nil, progress: Progress) {
        var userInfo: [String: Any] = [
            PHAssetProgressNotification.UserInfo.Key.progress: Float(progress.fractionCompleted)
        ]

        if let assetItem = item {
            userInfo[PHAssetProgressNotification.UserInfo.Key.assetItem] = assetItem
        }

        NotificationCenter.default.post(name: PHAssetProgressNotification.Name.progressChanged, object: self, userInfo: userInfo)
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
