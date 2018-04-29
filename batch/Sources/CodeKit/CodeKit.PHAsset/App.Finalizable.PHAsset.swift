//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos


public enum PHAssetFinalizingPresets: Int{
    case modify
    case create
    case delete
    case share
}

public protocol PHAssetFinalizableApp: FinalizableApp {
    var finalizingPresets: [PHAssetFinalizingPresets]? {get}
}

extension PHAssetFinalizableApp {

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        if result.isAnyTask(inState: .cancelled) && result.defaultTaskPolicy.cancellation == TaskPolicy.Cancellation.shallow {
            return result
        }

        guard let finalizingPresets = self.finalizingPresets else {
            return result
        }

        // filter only completed.
        let result = result.filter { respondable in respondable.info.state == .completed }

        // map target assets
        let targetResultAssets = result.compactMap {
            $0.result as? PHAssetResultable
        }

        if targetResultAssets.count == 0{
            return result
        }

        let exclusiveOption = finalizingPresets.count==1
        for option in finalizingPresets{
            if option == .delete{
                self.deletingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }

            if option == .modify{
                self.modifyingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }

            if option == .create{
                self.creatingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }

            if option == .share{
                self.sharingAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }
        }
        assert(asyncSignal.began == false)
        return result
    }

    private func modifyingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncManualSignalable){
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            for result in targetResultAssets{
                PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
            }

        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("modifyingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }

    private func deletingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncManualSignalable){
        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(targetResultAssets.map { $0.asset } as NSArray)
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("deletingAndWait", success)

            if !success{


            }
        })
        asyncSignal.waitUntilEnd()
    }

    private func sharingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncManualSignalable){
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            asyncSignal.begin()
            DispatchQueue.global().async {

                let activityItems = targetResultAssets.compactMap { (resultable: PHAssetResultable) -> Any? in
                    return self.routeUIActivityShareItems(by:resultable)
                }

                DispatchQueue.main.async {
                    let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    activityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
                        asyncSignal.end()
                    }
                    activityViewController.popoverPresentationController?.sourceView = rootVC.view
                    rootVC.present(activityViewController, animated: true, completion: nil)
                }
            }
            asyncSignal.waitUntilEnd()
        }
    }

    private func routeUIActivityShareItems(by result:PHAssetResultable) -> Any?{
        /*
        case photo
        case video
        case audio
        case alternatePhoto
        case fullSizePhoto
        case fullSizeVideo
        case adjustmentData
        case adjustmentBasePhoto
        case pairedVideo
        case fullSizePairedVideo
        case adjustmentBasePairedVideo
        */

        /*
        UTItype

        https://developer.apple.com/documentation/mobilecoreservices/uttype
        https://developer.apple.com/documentation/mobilecoreservices/uttype/uti_image_content_types

        kUTTypeImage
        kUTTypeJPEG
        kUTTypeJPEG2000
        kUTTypeTIFF
        kUTTypePICT
        kUTTypeGIF
        kUTTypePNG
        kUTTypeQuickTimeImage
        kUTTypeAppleICNS
        kUTTypeBMP
        kUTTypeICO
        */
        switch (result.asset.mediaType){
            case .image:
                if let imageUrl = result.contentEditingOutput?.renderedContentURL{
                    return try? Data(contentsOf: imageUrl)
                }

                return result.asset.asUIImage

//                let resources = PHAssetResource.assetResources(for: asset)
//                if resources.count > 1{
//                    for r in resources{
//                        switch(r.type){
//                            case .photo, .alternatePhoto, .fullSizePhoto, .adjustmentBasePhoto:
//                                return asset.asUIImage
//
//                            default:
//                                return nil
//                        }
//                    }
//
//                }else{
//                    return asset.asUIImage
//                }
            default:
                return nil
        }
    }

    private func creatingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncManualSignalable){
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            for result in targetResultAssets{
                if let output = result.contentEditingOutput{
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL:output.renderedContentURL)
                }
            }

        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("creatingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }
}
