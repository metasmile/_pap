//
// Created by BLACKGENE on 18.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Vision

public protocol VisionSourceable:ImageSourceable {
    var asFaceBoundingBoxes:[CGRect]? { get }
}

extension VisionSourceable{
    public var asFaceBoundingBoxes: [CGRect]? {
        guard let ciImage = self.asCIImage else{
            return nil
        }

        var faceBoundingBoxes:[CGRect]?
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        //VNDetectFaceRectanglesRequest is sync
        try? handler.perform([(VNDetectFaceRectanglesRequest { (request, error) in
            faceBoundingBoxes = (request.results as? [VNFaceObservation])?.compactMap({ $0.boundingBox })
        })])

        return faceBoundingBoxes?.nilEmpty
    }
}