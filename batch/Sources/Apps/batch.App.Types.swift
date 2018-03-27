//
// Created by BLACKGENE on 13/03/2018.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public protocol ItemCollectableApp: App {
    func isItemEnables(for:PHAssetItem<AppValue>) -> Bool
}

public protocol PhotoPickerViewControllerDisplayableApp: App {
    func titleWillBegin() -> String?
    func titleDidUpdate(progress: Float) -> String?
    func titleWillCancel() -> String?
    func titleWillFinalize() -> String?
}

extension PhotoPickerViewControllerDisplayableApp {
    public func titleWillBegin() -> String? {
        return nil
    }

    public func titleDidUpdate(progress: Float) -> String? {
        return nil
    }

    public func titleWillCancel() -> String? {
        return nil
    }

    public func titleWillFinalize() -> String? {
        return nil
    }
}