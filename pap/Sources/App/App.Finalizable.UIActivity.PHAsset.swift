//
// Created by BLACKGENE on 17.05.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import UIKit

public struct PHAssetFinalizingActivityItem {
    var input: AppAsset?
    var output: PHAssetFinalizingOutput?
}

public struct PHAssetFinalizingOutput {
    var resources: [(resourceType: PHAssetResourceType, url: URL)] = []
}

protocol PHAssetUIActivityFinalizableApp: PHAssetFinalizableApp{}

extension PHAssetUIActivityFinalizableApp{
    public func presentFinalizingActivity(items: [PHAssetFinalizingActivityItem]?, _ asyncSignal: AsyncWaitSignalable) {
        asyncSignal.begin()
        DispatchQueue.main.async {
            if let shareItems = items, shareItems.count > 0, let rootViewController = UIViewController.presentable {
                let activities = self.finalizingActions.map { PHAssetFinalizingActivity($0, finalizingActivityItems: shareItems) }

                let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: activities)
                activityViewController.excludedActivityTypes = [UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print, UIActivity.ActivityType.assignToContact]
                activityViewController.completionWithItemsHandler = { (activityType:UIActivity.ActivityType?, completed:Bool, returnedItems:[Any]?, activityError:Error?) in
                    asyncSignal.end()
                }
                activityViewController.setDefaultPopoverPresentationControllerIfUndefined(sourceView:rootViewController.view)
                rootViewController.present(activityViewController, animated: true, completion: nil)

            }else{
                asyncSignal.end()
            }
        }
        asyncSignal.waitUntilEnd()
    }
}

internal class PHAssetFinalizingActivity: UIActivity {
    override class var activityCategory: UIActivity.Category {
        return .action
    }

    init(_ finalizingActions: PHAssetFinalizingAction, finalizingActivityItems: [PHAssetFinalizingActivityItem]) {
        super.init()

        presets = finalizingActions
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

    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType(rawValue: (Bundle.main.bundleIdentifier ?? "") + (activityTitle ?? ""))
    }

    private var presets: PHAssetFinalizingAction?
    private var activityItems: [PHAssetFinalizingActivityItem]?

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems is [PHAssetFinalizingActivityItem]
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
    func modifyingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncWaitSignalable = AsyncSignal()){
        asyncSignal.begin()
        PHPhotoLibrary.shared().performChanges({
            items.forEach { item in
                guard let input = item.input, let resource = item.output?.resources.first else { return }

                input.requestContentEditing({ (contentEditingItem) in
                    if let output = contentEditingItem?.output, (try? FileManager.default.moveItem(at: resource.url, to: output.renderedContentURL)) == nil {
                        PHAssetChangeRequest(for: input.asset).contentEditingOutput = output
                    }
                })
            }
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("modifyingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }

    func creatingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncWaitSignalable = AsyncSignal()){
        print("creatingAndWait", items.count)
        try? PHPhotoLibrary.shared().performChangesAndWait {
            items.forEach { item in
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true

                item.output?.resources.forEach {
                    request.addResource(with: $0.resourceType, fileURL: $0.url, options: options)
                }
            }
        }
        print("creatingAndWait end")
    }

    func deletingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncWaitSignalable = AsyncSignal()){
        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(items.compactMap { $0.input?.asset } as NSArray)
        }, completionHandler: { (success, info) in
            asyncSignal.end()
            print("deletingAndWait", success)
        })
        asyncSignal.waitUntilEnd()
    }

    func sharingAndWait(items:[PHAssetFinalizingActivityItem], _ asyncSignal: AsyncWaitSignalable = AsyncSignal()){
        asyncSignal.begin()

        let items = items.compactMap({ $0.output?.resources }).reduce([],+).map { $0.url }
        UIActivityViewController.share(activityItems: items, excludedActivityTypes:[UIActivity.ActivityType.saveToCameraRoll]) { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
            asyncSignal.end()
        }

        asyncSignal.waitUntilEnd()
    }
}
