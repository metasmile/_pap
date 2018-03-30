//
// Created by BLACKGENE on 15/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos


typealias PHAssetContentEditingHandler = (PHAssetContentEditingItem?) -> Void
typealias PHAssetEditableCompletionHandler = (PHAsset?, PHContentEditingOutput?) -> Void

protocol PHAssetProcessable {}

protocol ImageProcessable: PHAssetProcessable {}
class ImageProcessor: ImageProcessable {}

protocol VideoProcessable: PHAssetProcessable {}
class VideoProcessor: VideoProcessable {}

protocol LivePhotoProcessable: PHAssetProcessable {}
class LivePhotoProcessor: LivePhotoProcessable {}
class LivePhotoAdvancedProcessor: LivePhotoProcessor {}

protocol PHAssetImageEditable {
    func edit<T:ImageProcessable>(processor:T, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
}

protocol PHAssetVideoEditable{
    func edit<T:VideoProcessable>(processor:T, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
}

protocol PHAssetLivePhotoEditable{
    func edit<T:LivePhotoProcessable>(processor:T, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
}

struct PHAssetContentEditingItem {
    var requestID: PHContentEditingInputRequestID
    var input:PHContentEditingInput
    var info:[AnyHashable : Any]?
    var output:PHContentEditingOutput
}

extension PHAssetItem {

    @discardableResult
    func requestContentEditing(_ block: @escaping PHAssetContentEditingHandler) -> PHContentEditingInputRequestID {
        var requestID:PHContentEditingInputRequestID?

        requestID = asset.requestContentEditingInput(with: nil) { (input, info) in
            guard let _requestID = requestID else {
                block(nil)
                return
            }
            guard let _input = input else {
                block(nil)
                return
            }
            guard let dataInfo = "Edited".data(using: .utf8) else {
                block(nil)
                return
            }

            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: _input)
            contentEditingOutput.adjustmentData = PHAdjustmentData(formatIdentifier: Bundle.main.bundleIdentifier ?? "", formatVersion: "1.0", data: dataInfo)

            block(PHAssetContentEditingItem(requestID: _requestID, input: _input, info: info, output: contentEditingOutput))
        }
        return requestID!
    }

    func runEditing(_ progressHandler: ((Float) -> Void)? = nil, _ completionHandler: @escaping PHAssetEditableCompletionHandler) {

        NotificationCenter.default.addObserver(forName: RemoteSourceFetchNotification.Name.fetchBagan, object: asset, queue: nil) { notification in
            if let _requestId = notification.userInfo?[RemoteSourceFetchNotification.UserInfo.Key.imageRequestID] as? PHImageRequestID{
                self.requestIDs.append(PHAssetRequestID(forImage:_requestId))
            }
        }

        if let requestIDs = { () -> [PHAssetRequestID]? in

            switch (asset.mediaType){
                case .image where asset.mediaSubtypes.contains(.photoLive):
                    return (self as? PHAssetLivePhotoEditable)?.edit(processor: LivePhotoProcessor(), completion: completionHandler)
        //                return self.edit(processor: LivePhotoAdvancedProcessor(), completion: completionHandler)
                case .image:
                    return (self as? PHAssetImageEditable)?.edit(processor: ImageProcessor(), completion: completionHandler)
                case .video:
                    return (self as? PHAssetVideoEditable)?.edit(processor: VideoProcessor(), completion: completionHandler)
                default:
                    return nil
            }
        }() {

            self.requestIDs += requestIDs
        }
    }

    func cancelAllRequestIDs() {

        for req in requestIDs{
            if req.forImage != PHAssetRequestID.DefaultValue.forImage{
                print(req.forImage)
                PHImageManager.default().cancelImageRequest(req.forImage)
            }

            if req.forEditingInput != PHAssetRequestID.DefaultValue.forEditingInput{
                asset.cancelContentEditingInputRequest(req.forEditingInput)
            }

            if req.forResourceData != PHAssetRequestID.DefaultValue.forResourceData{
                PHAssetResourceManager.default().cancelDataRequest(req.forResourceData)
            }
        }
    }
}
