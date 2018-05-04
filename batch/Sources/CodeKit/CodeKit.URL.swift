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

extension Array where Element == URL {
    public var mapAsPath:[String]{
        return self.map { url -> String in
            return url.path
        }
    }
}

extension Array where Element == String {
    public var mapAsFileURL:[URL]{
        return self.map { path -> URL in
            let url = URL(fileURLWithPath: path)
            assert(url.isFileURL, "\(path) is not valid file url")
            return url
        }
    }
}