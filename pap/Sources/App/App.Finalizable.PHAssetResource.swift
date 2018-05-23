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

public protocol PHAssetResourceFinalizableApp: FinalizableApp {
    var createdAssetLocalIdentifiers: [String]? {get}
}

extension PHAssetResourceFinalizableApp {
    public func finalize(result: [AppTaskRespondable], _ asyncSignal: AsyncManualSignalable) -> [AppTaskRespondable] {
        return result
    }
    
    public func createPHAssets(from outputs: [PHAssetResourceFinalizingOutput]) -> [String] {
        var localIdentifiers = [String]()
        
        try? PHPhotoLibrary.shared().performChangesAndWait {
            for item in outputs {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                
                item.resources.forEach { resourceOutput in
                    request.addResource(with: resourceOutput.resourceType, fileURL: resourceOutput.url, options: options)
                }
                
                if let identifier = request.placeholderForCreatedAsset?.localIdentifier {
                    localIdentifiers.append(identifier)
                }
            }
        }
        return localIdentifiers
    }
}
