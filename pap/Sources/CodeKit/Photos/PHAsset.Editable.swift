//
// Created by BLACKGENE on 15/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos


typealias PHAssetContentEditingHandler = (PHAssetContentEditingItem?) -> Void
typealias PHAssetEditableProgressHandler = (Progress) -> Void
typealias PHAssetEditableCompletionHandler = (PHAsset?, PHContentEditingOutput?) -> Void

public struct PHAssetProgressNotification {
    enum Name {
        static let progressChanged = Notification.Name("PHAssetProcessableNotificationProgressChanged")
    }
    
    struct UserInfo {
        enum Key {
            static let progress = "progress"
            static let assetItem = "assetItem"
        }
    }
}

protocol PHAssetProcessable {}

protocol ImageProcessable: PHAssetProcessable {}
class ImageProcessor: ImageProcessable {}

protocol VideoProcessable: PHAssetProcessable {}
class VideoProcessor: VideoProcessable {}

protocol LivePhotoProcessable: PHAssetProcessable {}
class LivePhotoProcessor: LivePhotoProcessable {}
class LivePhotoAdvancedProcessor: LivePhotoProcessable {}

protocol PHAssetImageEditable {
    func edit<T:ImageProcessable>(processor:T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
}

protocol PHAssetVideoEditable{
    func edit<T:VideoProcessable>(processor:T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
}

protocol PHAssetLivePhotoEditable{
    func edit<T:LivePhotoProcessable>(processor:T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
}

struct PHAssetContentEditingItem {
    var requestID: PHContentEditingInputRequestID
    var input:PHContentEditingInput
    var info:[AnyHashable : Any]?
    var output:PHContentEditingOutput
}

struct PAPAdjustmentData {
    static let formatVersion = "1.0"
    static let formatIdentifier = "\(Bundle.main.bundleIdentifier ?? "com.stells.pap").PHAsset.adjustmentData"
    
    static func isVaildAdjustmentData(_ data: PHAdjustmentData?) -> Bool {
        return data?.formatIdentifier == PAPAdjustmentData.formatIdentifier
    }
    
    static func createAdjustmentData(for app: App.Type, editInfo: [String: Any], from asset: PHAsset? = nil) -> PHAdjustmentData {
        return createAdjustmentData(with: app.info.identifier, editInfo: editInfo, from: asset)
    }
    
    static func createAdjustmentData(with appIdentifier: String, editInfo: [String: Any], from asset: PHAsset? = nil) -> PHAdjustmentData {
        // history
        var history = [[String: Any]]()
        
        //TODO: fetch previous history
//        var previousAdjustmentData: PHAdjustmentData?
//        if isVaildAdjustmentData(previousAdjustmentData), let previousEditData = previousAdjustmentData?.data, let previousEditInfo = try? JSONSerialization.jsonObject(with: previousEditData) as? [String: AnyObject] {
//            if let previousHistory = previousEditInfo?["history"] as? [[String: Any]] {
//                history.append(contentsOf: previousHistory)
//            }
//        }
        
        var editInfo = editInfo
        editInfo["id"] = appIdentifier
        if let source = asset?.localIdentifier {
            editInfo["source"] = source
        }
        history.append(editInfo)
        
        var adjustmentInfo: [String: Any] = [
            "id": appIdentifier,
            "editInfo": editInfo,
            "history": history
        ]
        if let source = asset?.localIdentifier {
            adjustmentInfo["source"] = source
        }
        
        let data: Data
        if let json = try? JSONSerialization.data(withJSONObject: adjustmentInfo, options: .prettyPrinted) {
            data = json
        }
        else {
            data = Data()
        }
        
        print("edited", adjustmentInfo)
        
        let adjustmentData = PHAdjustmentData(formatIdentifier: PAPAdjustmentData.formatIdentifier, formatVersion: PAPAdjustmentData.formatVersion, data: data)
        
        return adjustmentData
    }
}

extension AppAssetItem {

    @discardableResult
    func requestContentEditing(options:PHContentEditingInputRequestOptions?=nil, _ block: @escaping PHAssetContentEditingHandler) -> PHContentEditingInputRequestID {
        var requestID:PHContentEditingInputRequestID?

        requestID = asset.requestContentEditingInput(with: options) { (input, info) in
            guard let _requestID = requestID else {
                block(nil)
                return
            }
            guard let _input = input else {
                block(nil)
                return
            }

            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: _input)
            block(PHAssetContentEditingItem(requestID: _requestID, input: _input, info: info, output: contentEditingOutput))
        }
        return requestID!
    }

    func runEditing(_ progressHandler: PHAssetEditableProgressHandler? = nil, _ completionHandler: @escaping PHAssetEditableCompletionHandler) {

        NotificationCenter.default.addObserver(forName: RemoteSourceFetchNotification.Name.fetchBagan, object: asset, queue: nil) { notification in
            if let _requestId = notification.userInfo?[RemoteSourceFetchNotification.UserInfo.Key.imageRequestID] as? PHImageRequestID{
                self.appendRequestId(PHAssetRequestID(forImage:_requestId))
            }
        }

        if let requestIDs = { () -> [PHAssetRequestID]? in

            switch (asset.mediaType){
                case .image where asset.mediaSubtypes.contains(.photoLive):
                    return (self as? PHAssetLivePhotoEditable)?.edit(processor: LivePhotoProcessor.self, progress: progressHandler, completion: completionHandler)
                case .image:
                    return (self as? PHAssetImageEditable)?.edit(processor: ImageProcessor.self, progress: progressHandler, completion: completionHandler)
                case .video:
                    return (self as? PHAssetVideoEditable)?.edit(processor: VideoProcessor.self, progress: progressHandler, completion: completionHandler)
                default:
                    return nil
            }
        }() {

            for id in requestIDs{
                self.appendRequestId(id)
            }
        }
    }

    func cancelAllRequestIDs() {
        
        for req in requestIDs ?? []{
            if req.forImage != PHAssetRequestID.DefaultValue.forImage{
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
