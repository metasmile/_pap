//
// Created by BLACKGENE on 2018-09-28.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos
import FirebaseMLVision

//temp//temp//temp
struct VisionTextPHAssetDetectResult: VisionTextDetectResult, AppTaskResultable {
    let asset:PHAsset

    init(asset:PHAsset){
        self.asset = asset
    }

    var sourceVisionTexts:[VisionText]?

    var plainText:String?

    var contacts:[VisionTextContactParser.OutputType]?

    var resultGroup: VisionTextResultGroup?
}


struct VisionTextImageDetectResult: VisionTextDetectResult, AppTaskResultable {
    let image:UIImage

    init(image:UIImage){
        self.image = image
    }

    var sourceVisionTexts:[VisionText]?

    var plainText:String?

    var contacts:[VisionTextContactParser.OutputType]?

    var resultGroup: VisionTextResultGroup?
}

