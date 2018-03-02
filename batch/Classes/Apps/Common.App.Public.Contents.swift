//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PHAssetItem where EditStateValueType: BatchAppPHAssetState {}

public class BatchAppPHAssetState: ItemObject {}

public protocol PHAssetEditableFinalizableApp: FinalizableApp {}

extension PHAssetEditableFinalizableApp {
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable] {

        if result.isAnyTask(inState: .cancelled) && result.defaultTaskPolicy.cancellation == TaskPolicy.Cancellation.shallow {
            return result
        }

        let editedResultAssets = result.flatMap {
            $0.result as? PHAssetResultable
        }.filter {
            resultable in resultable.contentEditingOutput != nil
        }

        if editedResultAssets.count > 0{
            asyncSignal.begin()

            PHPhotoLibrary.shared().performChanges({
                for result in editedResultAssets {
                    PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
                }
            }, completionHandler: { (success, info) in

                asyncSignal.end()
            })
        }

        if asyncSignal.began{
            asyncSignal.stopUntilEnd()
        }

        return result
    }
}

