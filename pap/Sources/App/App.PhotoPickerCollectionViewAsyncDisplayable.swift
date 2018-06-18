//
// Created by BLACKGENE on 18.06.18.
// Copyright (c) 2018 Stells. All rights reserved.
//

import Foundation

public enum PhotoPickerCollectionViewAsyncSelection: Int{
    case none
    case visible
}

public protocol PhotoPickerCollectionViewAsyncDisplayableApp: App{
    func selectAsynchronously(item:AppAsset, _ async:AsyncSignal) -> PhotoPickerCollectionViewAsyncSelection
}

