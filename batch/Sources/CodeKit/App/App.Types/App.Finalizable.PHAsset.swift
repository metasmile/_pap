//
// Created by BLACKGENE on 27/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos


public struct PHAssetFinalizingOptions: SequenceOptionSet {
    static let modify = PHAssetFinalizingOptions(rawValue: 1 << 0)
    static let create = PHAssetFinalizingOptions(rawValue: 1 << 1)
    static let delete = PHAssetFinalizingOptions(rawValue: 1 << 2)
    static let share = PHAssetFinalizingOptions(rawValue: 1 << 3)

    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public protocol PHAssetFinalizableApp: FinalizableApp {
    var finalizingOptions: PHAssetFinalizingOptions {get}
}

extension PHAssetFinalizableApp {

    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        if result.isAnyTask(inState: .cancelled) && result.defaultTaskPolicy.cancellation == TaskPolicy.Cancellation.shallow {
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

        let exclusiveOption = self.finalizingOptions.underestimatedCount==1
        for option in self.finalizingOptions{
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
        })
        asyncSignal.waitUntilEnd()
    }

    private func sharingAndWait(targetResultAssets:[PHAssetResultable], _ asyncSignal: AsyncManualSignalable){
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            asyncSignal.begin()
            DispatchQueue.global().async {
                //TODO: fix problems
                let datas = targetResultAssets.compactMap { (resultable: PHAssetResultable) -> Data? in
                    return resultable.asset.asData
                }

                DispatchQueue.main.async {
                    let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: datas, applicationActivities: nil)
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
