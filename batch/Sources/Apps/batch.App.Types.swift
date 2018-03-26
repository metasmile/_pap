//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol ItemCollectableApp: App {
//    var asyncSignal:Dictionary<String, AsyncControllableSignable & AsyncSignalable>? {get}

    func isItemEnables(for:PHAssetItem<AppValue>) -> Bool
}
