//
// Created by BLACKGENE on 2018-09-28.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import FirebaseMLVision
import Photos

//temp//temp//temp

protocol VisionTextDetectResult {
    var sourceVisionTexts:[VisionText]? {set get}

    var plainText:String? {set get}

    var contacts:[VisionTextContactParser.OutputType]? {set get}

    var resultGroup: VisionTextResultGroup? {set get}
}


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

