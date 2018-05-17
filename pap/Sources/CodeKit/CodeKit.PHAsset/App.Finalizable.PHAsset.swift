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
    var finalizingPresets: [PHAssetFinalizingPresets] {get}
}

extension PHAssetFinalizableApp{
    public var finalizingPresets: [PHAssetFinalizingPresets] {
        return [.share]
    }
}

extension PHAssetFinalizableApp {

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        let finalizingPresets = self.finalizingPresets

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

extension PHAssetFinalizableApp {
    public func presentFinalizingActivity(items: [PHAssetFinalizingActivityItem]?, _ asyncSignal: AsyncManualSignalable) {
        asyncSignal.begin()
        DispatchQueue.main.async {
            if let shareItems = items, shareItems.count > 0, let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                let activities = self.finalizingPresets.map { PHAssetFinalizingActivity($0, finalizingActivityItems: shareItems) }
                
                let activityViewController = UIActivityViewController(activityItems: shareItems.compactMap({ $0.output?.resources }).reduce([],+).map { $0.url }, applicationActivities: activities)
                activityViewController.excludedActivityTypes = [UIActivityType.saveToCameraRoll, UIActivityType.copyToPasteboard, UIActivityType.print, UIActivityType.assignToContact]
                activityViewController.completionWithItemsHandler = { (activityType:UIActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                    asyncSignal.end()
                }
                activityViewController.popoverPresentationController?.sourceView=rootViewController.view
                rootViewController.present(activityViewController, animated: true, completion: nil)
                
            }else{
                asyncSignal.end()
            }
        }
        asyncSignal.waitUntilEnd()
    }
}

public struct PHAssetFinalizingActivityItem {
    var input: AppAsset?
    var output: PHAssetFinalizingOutput?
}

public struct PHAssetFinalizingOutput {
    var resources: [(resourceType: PHAssetResourceType, url: URL)] = []
}

internal class PHAssetFinalizingActivity: UIActivity {
    override class var activityCategory: UIActivityCategory {
        return .action
    }
    
    init(_ finalizingPresets: PHAssetFinalizingPresets, finalizingActivityItems: [PHAssetFinalizingActivityItem]) {
        super.init()
        
        presets = finalizingPresets
        activityItems = finalizingActivityItems
    }
    
    override var activityTitle: String? {
        switch presets {
        case .create?: return "Create".localized
        case .modify?: return "Modify".localized
        case .delete?: return "Delete".localized
        case .share?: return "Share".localized
        default: return nil
        }
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: (Bundle.main.bundleIdentifier ?? "") + (activityTitle ?? ""))
    }
    
    private var presets: PHAssetFinalizingPresets?
    private var activityItems: [PHAssetFinalizingActivityItem]?
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems.contains(where: { $0 is URL })
    }
    
    override func perform() {
        switch presets {
        case .create?: creatingAndWait(items: activityItems ?? [])
        case .modify?: modifyingAndWait(items: activityItems ?? [])
        case .share?: sharingAndWait(items: activityItems ?? [])
        case .delete?: deletingAndWait(items: activityItems ?? [])
        default: break
        }
        
        activityDidFinish(true)
    }
}

extension PHAssetFinalizingActivity {
    func modifyingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncManualSignalable = AsyncSignal()){
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            items.forEach { item in
                guard let input = item.input, let resource = item.output?.resources.first else { return }
                asyncSignal.begin()
                input.requestContentEditing({ (contentEditingItem) in
                    if let output = contentEditingItem?.output, (try? FileManager.default.moveItem(at: resource.url, to: output.renderedContentURL)) == nil {
                        PHAssetChangeRequest(for: input.asset).contentEditingOutput = output
                    }
                    asyncSignal.end()
                })
            }
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("modifyingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }
    
    func creatingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncManualSignalable = AsyncSignal()){
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            items.forEach { item in
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                
                item.output?.resources.forEach {
                    request.addResource(with: $0.resourceType, fileURL: $0.url, options: options)
                }
            }
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("creatingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }
    
    func deletingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncManualSignalable = AsyncSignal()){
        asyncSignal.begin()
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(items.compactMap { $0.input?.asset } as NSArray)
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("deletingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }
    
    func sharingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncManualSignalable = AsyncSignal()){
//        asyncSignal.begin()
        DispatchQueue.main.async {
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: items.compactMap({ $0.output?.resources }).reduce([],+).map { $0.url }, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivityType.saveToCameraRoll]
            activityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
//                asyncSignal.end()
            }
            
            activityViewController.popoverPresentationController?.sourceView = UIApplication.shared.keyWindow?.rootViewController?.view
            UIApplication.shared.keyWindow?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
//        asyncSignal.waitUntilEnd()
    }
}
