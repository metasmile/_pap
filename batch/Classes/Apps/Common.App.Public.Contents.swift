//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PHAssetItem where EditStateValueType: BatchAppPHAssetState {}

public class BatchAppPHAssetState: ItemObject {}

public protocol PHAssetEditableFinalizableAppable: FinalizableAppable {}

extension PHAssetEditableFinalizableAppable {
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: TaskAsyncSignalable) -> [AppTaskRespondable] {

        let resultAssets = result.flatMap { $0.result as? PHAssetResultable }

        let editedResultAssets = resultAssets.filter { resultable in resultable.contentEditingOutput != nil }

        if editedResultAssets.count > 0{
            asyncSignal.begin()

            PHPhotoLibrary.shared().performChanges({
                for result in resultAssets {
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

