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

public protocol PHAssetFinalizableApp: FinalizableApp {
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

    internal func modifyingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
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

    internal func deletingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(targetResultAssets.map { $0.asset } as NSArray)
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("deletingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }

    internal func sharingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
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

    internal func creatingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncWaitSignalable){
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            for result in targetResultAssets{
                let request = PHAssetCreationRequest.forAsset()
                result.editingResultItems?.forEach {
                    request.addResource(with: $0.resourceType, fileURL: $0.url, options: nil)
                }
            }

        }, completionHandler: { (success, info) in
            assert(success,"PHAssetFinalizableApp.creatingAndWait -> failed")
            asyncSignal.end()
        })
        asyncSignal.waitUntilEnd()
    }


    internal func showingActionsAndWait(targetResultAssets:[PHAssetResultable], excludedActions: [PHAssetFinalizingAction] = [], _ asyncSignal: AsyncWaitSignalable){
        let actionQueue = DispatchQueue.global()
        let actionSignal = AsyncSignal()
        
        var numberOfImages = 0
        var numberOfVideos = 0
        for asset in targetResultAssets.map({ $0.asset }) {
            if asset.mediaType == .image {
                numberOfImages += 1
            }
            else if asset.mediaType == .video {
                numberOfVideos += 1
            }
        }
        
        let numberOfItems = PHAsset.formattedNumberString(numberOfImages: numberOfImages, numberOfVideos: numberOfVideos).localizedLowercase
        
        var excludedActions = excludedActions
        
        //INFO: can not export live photo
        if targetResultAssets.contains(where: { $0.editingResultItems?.isLivePhoto == true }) {
            excludedActions.append(.share)
        }

        let alert = UIAlertController.actionSheet(title: "Choose an export option for %@".localizedFormatted(numberOfItems), message: nil)
        if !excludedActions.contains(.create) {
            alert.addAction(UIAlertAction(title: "Save".localized, style: .default, handler: { action in
                actionQueue.async{
                    self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }
        if !excludedActions.contains(.share) {
            alert.addAction(UIAlertAction(title: "Share".localized, style: .default, handler: { action in
                actionQueue.async{
                    self.sharingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }
        if !excludedActions.contains(.modify) {
            alert.addAction(UIAlertAction(title: "Modify".localized, style: .default, handler: { action in
                actionQueue.async{
                    self.modifyingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }
        if !excludedActions.contains(.share) && !excludedActions.contains(.create) {
            alert.addAction(UIAlertAction(title: "Save and Share".localized, style: .default, handler: { action in
                actionQueue.async{
                    self.creatingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    self.sharingAndWait(targetResultAssets: targetResultAssets, actionSignal)
                    DispatchQueue.main.async{
                        asyncSignal.end()
                    }
                }
            }))
        }

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
        
        if result.editingResultItems?.count == 1, let editingResultItem = result.editingResultItems?.first {
            return editingResultItem.url as NSURL
        }
        else if result.editingResultItems?.isLivePhoto == true, let photo = result.editingResultItems?.item(for: .photo), let video = result.editingResultItems?.item(for: .pairedVideo) {
            var result: PHLivePhoto?
            let async = AsyncSignal()
            async.begin()
            LivePhotoWriter().createLivePhoto(imageURL: photo.url, withPairedVideo: video.url) { (livePhoto) in
                result = livePhoto
                async.end()
            }
            async.waitUntilEnd()
            return result
        }
        else {
            return nil
        }
    }
}

class PHAssetEditingResultViewController: UIViewController {
    
}
