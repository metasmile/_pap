//
// Created by BLACKGENE on 20/02/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

extension URL{
    public var asBundleURL: URL{
        return Bundle.main.bundleURL.appendingPathComponent(self.path)
    }

    public var asMetadataFromCIImage: [String: Any]?{
        return asCIImage?.properties
    }
}