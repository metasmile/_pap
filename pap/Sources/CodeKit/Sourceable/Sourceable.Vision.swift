//
// Created by BLACKGENE on 18.07.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Vision
import UIKit

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

extension CIImage: VisionSourceable {
    public var allFaces: [CIImage]? {
        guard let faces = self.asFaceBoundingBoxes else { return nil }
        let scale = CGAffineTransform(scaleX: extent.width, y: extent.height)
        return faces.map { self.cropped(to: $0.applying(scale)) }
    }
    
    public var faceGroup: CIImage? {
        guard let faces = self.asFaceBoundingBoxes?.union() else { return nil }
        let scale = CGAffineTransform(scaleX: extent.width, y: extent.height)
        return self.cropped(to: faces.applying(scale))
    }
}
