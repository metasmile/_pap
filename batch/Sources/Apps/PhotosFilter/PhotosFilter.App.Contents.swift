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

extension _PhotosFilterAppAsset: PHAssetImageEditable {
    func edit<T: ImageProcessable>(processor: T, completion completionHandler: @escaping PHAssetEditableCompletionHandler) -> [PHAssetRequestID]? {
        let asset = self.asset
        
        guard
            let uiImage = asset.asUIImage,
            let filter = self.editState.ciFilter
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
