//
//  PhotosFilter.App.Contents.swift
//  batch
//
//  Created by HYOJIN MO on 2018. 3. 28..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import AVFoundation

extension _PhotosFilterAppAsset: PHAssetImageEditable {
    func edit<T: ImageProcessable>(processor: T, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let asset = self.asset
        
        guard
            let uiImage = asset.asUIImage,
            let filter = editState.ciFilter
        else {
            completionHandler(nil, nil)
            return nil
        }
        
        let image = uiImage.applyFilter(ciFilter: filter)
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }
            
            DispatchQueue.global().async {
                // renderedContentURL supports only JPEG and MOV ...
                // so... always export JPEG
                //TODO: investigate PHAssetChangeRequest.creationRequestForAssetFromImage(url)
                let outputData = UIImageJPEGRepresentation(image, 1)
                
                guard (try? outputData?.write(to: item.output.renderedContentURL, options: .atomic)) != nil else {
                    completionHandler(nil, nil)
                    return
                }
                
                completionHandler(asset, item.output)
            }
        }
        return [PHAssetRequestID(forEditingInput: r)]
    }
}

extension _PhotosFilterAppAsset: PHAssetLivePhotoEditable {
    func edit<T:LivePhotoProcessable>(processor:T, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }
            
            self.editingContext = PHLivePhotoEditingContext(livePhotoEditingInput: item.input)
            self.editingContext?.frameProcessor = { frame, error in
                return frame.image.applyFilter(ciFilter: self.editState.ciFilter)
            }
            
            self.editingContext?.saveLivePhoto(to: item.output, options: nil, completionHandler: { (success, error) in
                guard success else {
                    completionHandler(nil, nil)
                    return
                }
                completionHandler(self.asset, item.output)
            })
        }
        
        return [PHAssetRequestID(forEditingInput: r)]
    }
}

extension _PhotosFilterAppAsset: PHAssetVideoEditable {
    func edit<T>(processor:T, /*audioMix: AVAudioMix? = nil,*/ progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
        where T:VideoProcessable {
            
            let asset = self.asset
            
            guard
                let video = asset.asAVAsset
                else {
                    completionHandler(nil, nil)
                    return nil
            }
            
            let videoComposition = video.applyFilter(editState.ciFilter)
            
            var reqIDs = [PHAssetRequestID]()
            
            let r = self.requestContentEditing { _item in
                guard let item = _item else{
                    completionHandler(nil,nil)
                    return
                }
                
                self.exportSession = AVAssetExportSession(asset: video, presetName: AVAssetExportPresetHighestQuality)
                self.exportSession?.outputFileType = AVFileType.mov
                self.exportSession?.outputURL = item.output.renderedContentURL
                self.exportSession?.videoComposition = videoComposition
                //            exportSession?.audioMix = audioMix
                self.exportSession?.shouldOptimizeForNetworkUse = false
                self.exportSession?.exportAsynchronously {
                    guard let status = self.exportSession?.status else { return }
                    switch status {
                    case .completed:
                        completionHandler(asset, item.output)
                    case .failed, .cancelled:
                        completionHandler(nil, nil)
                    default:
                        break
                    }
                }
            }
            
            reqIDs.append(PHAssetRequestID(forEditingInput: r))
            return reqIDs
    }
}
