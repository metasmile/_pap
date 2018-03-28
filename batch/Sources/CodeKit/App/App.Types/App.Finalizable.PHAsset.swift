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
        let targetResultAssets = result.flatMap {
            $0.result as? PHAssetResultable
        }/*.filter {
            resultable in resultable.contentEditingOutput != nil
        }*/

        if targetResultAssets.count == 0{
            return result
        }

        asyncSignal.begin()

        PHPhotoLibrary.shared().performChanges({
            //exclusive delete
            if self.finalizingOptions.underestimatedCount==1 && self.finalizingOptions.contains(.delete){
                PHAssetChangeRequest.deleteAssets(targetResultAssets.map { $0.asset } as NSArray)
                return
            }

            //TODO: .share
            for result in targetResultAssets {
                for option in self.finalizingOptions{
                    if option == .create, let output = result.contentEditingOutput{
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL:output.renderedContentURL)
                    }

                    if option == .modify{
                        PHAssetChangeRequest(for: result.asset).contentEditingOutput = result.contentEditingOutput
                    }

                    if option == .delete{
                        PHAssetChangeRequest.deleteAssets([result.asset] as NSArray)
                    }
                }
            }

        }, completionHandler: { (success, info) in
#if DEBUG
            if !success{
                print("PHAssetEditableFinalizableApp Error:", info!)
            }
#endif
            asyncSignal.end()
        })

        if asyncSignal.began{
            asyncSignal.stopUntilEnd()
        }

        return result
    }
}