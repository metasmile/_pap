//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol PHAssetItemCollectableApp: App {
    func areItemsEnables(for:PHAssetItem<AppValue>) -> Bool
}