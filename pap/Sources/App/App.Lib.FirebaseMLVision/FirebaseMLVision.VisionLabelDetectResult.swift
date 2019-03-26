//
// Created by BLACKGENE on 2018-11-30.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision
import Photos

protocol VisionLabelDetectResult {
    var sourceVisionLabels:[VisionLabel] {get}
}

struct VisionLabelPHAssetDetectResult: VisionLabelDetectResult, AppTaskResultable, Equatable, Hashable {
    let asset:PHAsset
    let sourceVisionLabels:[VisionLabel]
    let labelTextsConfidenceDescending:[String]

    init(asset:PHAsset, visionLabels:[VisionLabel]){
        self.asset = asset
        self.sourceVisionLabels = visionLabels
        self.labelTextsConfidenceDescending = visionLabels.sorted { l1, l2 in return l1.confidence > l2.confidence }.map { $0.label }
    }

    static func ==(lhs: VisionLabelPHAssetDetectResult, rhs: VisionLabelPHAssetDetectResult) -> Bool {
        return lhs.asset==rhs.asset
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(asset.hashValue)
    }

}

extension Array where Element==VisionLabelPHAssetDetectResult{

    var labelTextsConfidenceDescending:[String]{
        return map{ $0.sourceVisionLabels }.reduce([],+)
                .sorted { l1, l2 in return l1.confidence > l2.confidence }
                .map { $0.label }
                .uniq()
    }
}



