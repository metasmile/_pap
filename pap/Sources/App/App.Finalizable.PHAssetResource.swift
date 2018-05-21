//
//  App.Finalizable.PHAssetResource.swift
//  pap
//
//  Created by HYOJIN MO on 2018. 5. 21..
//  Copyright © 2018년 Stells. All rights reserved.
//

import UIKit

import Foundation
import Photos

public struct PHAssetResourceFinalizingOutput: TaskResultable {
    var orderedIndex: Int?
    var resources: [(resourceType: PHAssetResourceType, url: URL)]
    
    init(resources: [(resourceType: PHAssetResourceType, url: URL)] = [], orderedIndex: Int? = nil) {
        self.resources = resources
        self.orderedIndex = orderedIndex
    }
}

public struct PHAssetResourceFinalizingTaskRespondable: AppTaskRespondable {
    public var request: AppTaskRequest
    public var result: TaskResultable?
    public var info: TaskInfo
    
    public var assetLocalIdentifier: String? = nil
}

public protocol PHAssetResourceFinalizableApp: FinalizableApp {
    
}

extension PHAssetResourceFinalizableApp {
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        // filter only completed.
        let result = result
            .filter { respondable in respondable.info.state == .completed }
        
        return createPHAssets(result: result)
    }
    
    public func createPHAssets(result: [AppTaskRespondable]) -> [AppTaskRespondable] {
        var resultItems = [PHAssetResourceFinalizingTaskRespondable]()
        
        try? PHPhotoLibrary.shared().performChangesAndWait {
            for respondable in result {
                guard let item = respondable.result as? PHAssetResourceFinalizingOutput else { continue }
                
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                
                item.resources.forEach { resourceOutput in
                    request.addResource(with: resourceOutput.resourceType, fileURL: resourceOutput.url, options: options)
                }
                
                resultItems.append(PHAssetResourceFinalizingTaskRespondable(request: respondable.request, result: respondable.result, info: respondable.info, assetLocalIdentifier: request.placeholderForCreatedAsset?.localIdentifier))
            }
        }
        resultItems.sort(by: { ($0.result as? PHAssetResourceFinalizingOutput)?.orderedIndex ?? 0 < ($1.result as? PHAssetResourceFinalizingOutput)?.orderedIndex ?? 0
        })
        return resultItems
    }
}
