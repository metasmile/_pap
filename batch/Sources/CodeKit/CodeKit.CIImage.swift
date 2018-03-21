//
// Created by BLACKGENE on 21/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation
import Photos

extension CIImage{
    public func writeJPEGRepresentation(to:URL, options:[AnyHashable : Any] = [:]) -> Bool{
        do {
            try CIContext().writeJPEGRepresentation(of: self, to:to, colorSpace: self.colorSpace ?? CGColorSpaceCreateDeviceRGB(), options: options)
            return true

        } catch {
            return false
        }
    }
}
