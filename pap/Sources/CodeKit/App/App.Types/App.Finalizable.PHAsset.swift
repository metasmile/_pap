//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

public enum PHAssetFinalizingAction: Int{
    case modify
    case create
    case delete
    case share
    case actions
}

public protocol PHAssetFinalizableApp: FinalizableApp, PHAssetUIAlertControllerSynchronizablePresenter {
    var finalizingActions: [PHAssetFinalizingAction] {get}
}

extension PHAssetFinalizableApp{
    public var finalizingActions: [PHAssetFinalizingAction] {
        return [.share]
    }
}

extension PHAssetFinalizableApp {

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncWaitSignalable) -> [AppTaskRespondable] {
        let finalizingActions = self.finalizingActions

        // filter only completed.
        let result = result.filter { respondable in respondable.info.state == .completed }

        // map target assets
        let targetResultAssets = result.compactMap {
            $0.result as? PHAssetResultable
        }

        if targetResultAssets.count == 0{
            return result
        }

        let exclusiveOption = finalizingActions.count==1
        for option in finalizingActions{
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

            if option == .actions {
                self.showingActionsAndWait(targetResultAssets: targetResultAssets, asyncSignal)

                if exclusiveOption{ return result }
            }
        }
        assert(asyncSignal.began == false)
        return result
    }

    private func modifyingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
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

    private func deletingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(targetResultAssets.map { $0.asset } as NSArray)
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("deletingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }

    private func sharingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        if let _ = UIViewController.presentable {
            asyncSignal.begin()
            DispatchQueue.global().async {

                let activityItems = targetResultAssets.compactMap { (resultable: PHAssetResultable) -> Any? in
                    return self.routeUIActivityShareItems(by:resultable)
                }

                UIActivityViewController.share(activityItems: activityItems) { _, _, _, _ in
                    asyncSignal.end()
                }
            }
            asyncSignal.waitUntilEnd()
        }
    }

    private func creatingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
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


    private func showingActionsAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        let actionQueue = DispatchQueue.global()
        let actionSignal = AsyncSignal()

        let alert = UIAlertController.actionSheet(title: "Choose An Export Option For %d Items".localizedFormatted(targetResultAssets.count), message: nil)
        alert.addAction(UIAlertAction(title: "Save".localized, style: .default, handler: { action in
            actionQueue.async{
                self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                DispatchQueue.main.async{
                    asyncSignal.end()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Share".localized, style: .default, handler: { action in
            actionQueue.async{
                self.sharingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                DispatchQueue.main.async{
                    asyncSignal.end()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Modify".localized, style: .default, handler: { action in
            actionQueue.async{
                self.modifyingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                DispatchQueue.main.async{
                    asyncSignal.end()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Save and Share".localized, style: .default, handler: { action in
            actionQueue.async{
                self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                self.sharingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                DispatchQueue.main.async{
                    asyncSignal.end()
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { action in
            asyncSignal.end()
        }))

        asyncSignal.begin()

        DispatchQueue.main.async{
            UIViewController.present(alert, animated: true)
        }

        asyncSignal.waitUntilEnd()

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
}
