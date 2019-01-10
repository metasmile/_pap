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
            let ciImage = asset.asCIImage,
            let filter = editState.ciFilter
        else {
            completionHandler(nil, nil, nil)
            return nil
        }
        
        let image = ciImage.applyFilter(ciFilter: filter)
        
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil, nil, nil)
                return
            }
            
            DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
                // renderedContentURL supports only JPEG and MOV ...
                // so... always export JPEG
                //TODO: investigate PHAssetChangeRequest.creationRequestForAssetFromImage(url)
                
                guard image.writeJPEGRepresentationOriginally(to: item.output.renderedContentURL) else {
                    completionHandler(nil, nil, nil)
                    return
                }
                
                completionHandler(asset, [PHAssetEditingResultItem(url: item.output.renderedContentURL, resourceType: .photo)], item.output)
            }
        }
        return [PHAssetRequestID(forEditingInput: r)]
    }
}

extension _FiltersAppAsset: PHAssetLivePhotoEditable {
    func edit<T:LivePhotoProcessable>(processor:T.Type, progress progressHandler: PHAssetEditableProgressHandler?, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let r = self.requestContentEditing { _item in
            guard let item = _item else{
                completionHandler(nil, nil, nil)
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
                return autoreleasepool { frame.image.applyFilter(ciFilter: self.editState.ciFilter) }
            }
            
            self.editingContext?.saveLivePhoto(to: item.output, options: nil, completionHandler: { (success, error) in
                guard success else {
                    completionHandler(nil, nil, nil)
                    return
                }
                
                completionHandler(self.asset, [PHAssetEditingResultItem(url: item.output.renderedContentURL, resourceType: .photo)], item.output)
                
                //TODO: hmm.. how to get edited paired video??
                /*
                DispatchQueue(label: "com.stells.internal."+fileName(), qos: .utility).async {
                    guard let livePhoto = item.input.livePhoto else {
                        completionHandler(nil, nil, nil)
                        return
                    }
                    
                    let pairedVideoURL = FileURL.temp("pairedVideo", UTI.quickTimeMovie, group: FileURL.fileAndQueuePrivateGroup())
                    guard
                        let videoResource = PHAssetResource.assetResources(for: livePhoto).first(where: { $0.type == .pairedVideo }),
                        let videoData = videoResource.asData,
                        let _ = try? videoData.write(to: pairedVideoURL)
                        else {
                            completionHandler(nil, nil, nil)
                            return
                    }
                    
                    LivePhotoWriter.default.writeLivePhoto(photoPath: item.output.renderedContentURL.path, withVideo: pairedVideoURL.path, completion: { (success, photoURL, videoURL, error) in
                        guard let photoURL = photoURL, let videoURL = videoURL else {
                            completionHandler(nil, nil, nil)
                            return
                        }
                        
                        let resultItems = [
                            PHAssetEditingResultItem(url: photoURL, resourceType: .photo),
                            PHAssetEditingResultItem(url: videoURL, resourceType: .pairedVideo)
                        ]
                        completionHandler(self.asset, resultItems, item.output)
                    })
                }*/
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
                    completionHandler(nil, nil, nil)
                    return nil
            }
            
            var reqIDs = [PHAssetRequestID]()
            
            let r = self.requestContentEditing { _item in
                guard let item = _item else{
                    completionHandler(nil, nil, nil)
                    return
                }
                
                let playerItem = self.editState.playerItem(with: video, for: true)
                
                self.exportSession = AVAssetExportSession.export(asset: playerItem?.asset ?? video, videoComposition: playerItem?.videoComposition ?? video.applyFilter(self.editState.ciFilter), presetName: AVAssetExportPresetHighestQuality, outputURL: item.output.renderedContentURL, progressHandler: progressHandler, completionHandler: { (success) in
                    if success {
                        completionHandler(asset, [PHAssetEditingResultItem(url: item.output.renderedContentURL, resourceType: .video)], item.output)
                    }
                    else {
                        completionHandler(nil, nil, nil)
                    }
                })
            }
            
            reqIDs.append(PHAssetRequestID(forEditingInput: r))
            return reqIDs
    }
}
