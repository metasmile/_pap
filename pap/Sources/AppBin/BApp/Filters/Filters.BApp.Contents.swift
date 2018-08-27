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

class _FiltersAppAsset: AppAsset {
    fileprivate var editingContext: PHLivePhotoEditingContext?
    fileprivate var exportSession: AVAssetExportSession?
    
    func cancelProcessing() {
        editingContext?.cancel()
        editingContext = nil
        
        exportSession?.cancelExport()
        exportSession = nil
    }
}

extension _FiltersAppAsset: PHAssetImageEditable {
    func edit<T: ImageProcessable>(processor: T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let asset = self.asset

        guard
            let uiImage = asset.asUIImage,
            let filter = editState.ciFilter,
            let image = uiImage.applyFilter(ciFilter: filter)
        else {
            completionHandler(nil, nil)
            return nil
        }
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }
            
            DispatchQueue(label: "com.stells.internal."+#file, qos: .utility).async {
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

extension _FiltersAppAsset: PHAssetLivePhotoEditable {
    func edit<T:LivePhotoProcessable>(processor:T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil,nil)
                return
            }
            
            self.editingContext = PHLivePhotoEditingContext(livePhotoEditingInput: item.input)
            guard let duration = self.editingContext?.duration.seconds else { return }
            let progress = Progress(totalUnitCount: Int64(duration * 1000))
            self.editingContext?.frameProcessor = { frame, error in
                progressHandler?({
                    progress.completedUnitCount = Int64(frame.time.seconds * 1000)
                    return progress
                    }())
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

extension _FiltersAppAsset: PHAssetVideoEditable {
    func edit<T>(processor:T.Type, /*audioMix: AVAudioMix? = nil,*/ progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]?
        where T:VideoProcessable {
            
            let asset = self.asset
            
            guard
                let video = asset.asAVAsset
                else {
                    completionHandler(nil, nil)
                    return nil
            }
            
            var reqIDs = [PHAssetRequestID]()
            
            let r = self.requestContentEditing { _item in
                guard let item = _item else{
                    completionHandler(nil,nil)
                    return
                }
                
                self.exportSession = AVAssetExportSession.export(asset: video, videoComposition: video.applyFilter(self.editState.ciFilter), presetName: AVAssetExportPresetHighestQuality, outputURL: item.output.renderedContentURL, progressHandler: progressHandler, completionHandler: { (success) in
                    if success {
                        completionHandler(asset, item.output)
                    }
                    else {
                        completionHandler(nil, nil)
                    }
                })
            }
            
            reqIDs.append(PHAssetRequestID(forEditingInput: r))
            return reqIDs
    }
}
