//
// Created by BLACKGENE on 13/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension PHAssetItem where EditStateValueType: AppValue {}

public class AppValue: Object {
    var transform: CGAffineTransform {
        return .identity
    }
    var transform3d: CATransform3D {
        return CATransform3DIdentity
    }
}


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

//TODO: Finalizable Error
extension PHAssetFinalizableApp {
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
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
                //exclusive delete
                if self.finalizingOptions.underestimatedCount==1 && self.finalizingOptions.contains(.delete){
                    PHAssetChangeRequest.deleteAssets(editedResultAssets.map { $0.asset } as NSArray)
                    return
                }

                //TODO: .share
                for result in editedResultAssets {
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
        }

        if asyncSignal.began{
            asyncSignal.stopUntilEnd()
        }

        return result
    }
}

