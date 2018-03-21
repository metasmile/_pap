//
// Created by BLACKGENE on 29/01/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import MobileCoreServices

extension PHAsset {
    //https://developer.apple.com/library/content/samplecode/UsingPhotosFramework/Listings/Shared_AssetViewController_swift.html
    func revertToOriginal() {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: self)
            request.revertAssetContentToOriginal()
        }, completionHandler: { success, error in
            if !success { print("can't revert asset: \(String(describing: error))") }
        })
    }

    var pixelSize: CGSize {
        return CGSize(width: pixelWidth, height: pixelHeight)
    }

    public final func fetchAdjustmentData(completionHandler:@escaping (PHAdjustmentData?) -> Void){
        let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ -> Bool in
            return true
        }

        self.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
            completionHandler(contentEditingInput?.adjustmentData)
        })
    }

    @discardableResult
    public final func writeJPEGRepresentation(to url:URL, transformMetadata: @escaping (([String : Any]) -> [String : Any]?), completion:@escaping (Bool) -> Void ) -> PHContentEditingInputRequestID {
        return self.requestContentEditingInput(with: nil) { input, dictionary in

            guard let image = input?.fullSizeImageURL?.asCIImage
            , let metadata = transformMetadata(image.properties)
            , input?.uniformTypeIdentifier == kUTTypeJPEG as String else {
                completion(false)
                return
            }

            let modifiedImage = image.settingProperties(metadata)

            do {
                //TODO: investigate/apply relationship between input?.uniformTypeIdentifier and CIImage.properties
                //TODO: https://developer.apple.com/documentation/mobilecoreservices/uttype/uti_image_content_types
                try CIContext().writeJPEGRepresentation(of: modifiedImage, to:url, colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(), options: [:])
                completion(true)

            } catch {
                completion(false)
            }
        }
    }

    @discardableResult
    public final func fetchCIImage(completion: @escaping ((CIImage?) -> Void)) -> PHContentEditingInputRequestID {
        return self.requestContentEditingInput(with: nil) { input, dictionary in
            completion(input?.fullSizeImageURL?.asCIImage)
        }
    }

    /*
    asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (eidtingInput, info) in
                    if let input = eidtingInput, let imgURL = input.fullSizeImageURL {
                        // imgURL
                        print(imgURL)

                        //file:///var/mobile/Media/PhotoData/Mutations/DCIM/109APPLE/IMG_9931/Adjustments/FullSizeRender.jpg
                    }
                    signal.end()
           }
               */
}
